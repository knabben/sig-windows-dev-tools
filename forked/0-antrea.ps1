<#
Copyright 2021 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

# Force Kubernetes folder
mkdir -Force C:/k/

# Required configuration files symlink
New-Item -ItemType HardLink -Target "C:\etc\kubernetes\kubelet.conf" -Path "C:\k\config"

# Install NSSM: Workaround to privileged containers...
mkdir C:/nssm/ -Force
curl.exe -LO https://k8stestinfrabinaries.blob.core.windows.net/nssm-mirror/nssm-2.24.zip
tar C C:/nssm/ -xvf ./nssm-2.24.zip --strip-components 2 */$arch/*.exe
Remove-Item -Force ./nssm-2.24.zip

# Install antrea: CNI Provider
mkdir -Force C:/k/
mkdir -Force C:/k/antrea/ # scripts
mkdir -Force C:/k/antrea/bin/ #executables
mkdir -Force C:/k/antrea/etc/ # for antrea-agent.conf

$antreaInstallationFiles = @{
      "https://raw.githubusercontent.com/antrea-io/antrea/main/build/yamls/base/conf/antrea-cni.conflist" = "C:/etc/cni/net.d/10-antrea.conflist"
      "https://raw.githubusercontent.com/antrea-io/antrea/main/hack/windows/Install-OVS.ps1" =  "C:/k/antrea/Install-OVS.ps1"
      "https://raw.githubusercontent.com/antrea-io/antrea/main/hack/windows/Helper.psm1" = "C:/k/antrea/Helper.psm1"
      "https://github.com/antrea-io/antrea/releases/download/v1.3.0/antrea-agent-windows-x86_64.exe" = "C:/k/antrea/bin/antrea-agent.exe"
      "https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-windows-amd64-v0.9.1.tgz" = "C:/k/antrea/bin/cni-plugins-windows-amd64-v0.9.1.tgz"
      "https://dl.k8s.io/release/v1.21.0/bin/windows/amd64/kubectl.exe" = "C:/k/kubectl.exe"
      "https://raw.githubusercontent.com/antrea-io/antrea/main/build/yamls/windows/base/conf/antrea-agent.conf" = "C:/k/antrea/etc/antrea-agent.conf"
      "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe" = "C:\vc.exe"
      "https://slproweb.com/download/Win64OpenSSL-1_0_2u.exe" = "C:/Windows/Temp/Win64OpenSSL-1_0_2u.exe"
}

foreach ($theURL in $antreaInstallationFiles.keys) {
  $outPath = $antreaInstallationFiles[$theURL]
  Write-Output("1 - checking $outPath ... ")
  if (!(Test-Path $outPath)) {
     Write-Output("2 - Acquiring ---> $theURL writing to  $outPath")
     curl.exe -L $theURL -o $outPath
     # special logic for the host-local plugin...
     if ($theURL -eq "https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-windows-amd64-v0.9.1.tgz" ){
        tar -xvzf C:/k/antrea/bin/cni-plugins-windows-amd64-v0.9.1.tgz
        cp ./host-local.exe "C:/opt/cni/bin/host-local.exe"
     } else {
        Write-Output("Nothing to do: $outPath exists in the right place already...")
     }
     Write-Output("$outPath ::: DETAILS ...")
     Get-ItemProperty $outPath
     ls $outPath
     Write-Output("$outPath ::: DONE VERIFYING")
  }
  if (!(Test-Path $outPath)) {
    Write-Error "That download totally failed $outPath is not created...."
    exit 1
  }
}

# Installing MSDist find the really required one.
C:\Windows\Temp\Win64OpenSSL-1_0_2u.exe /silent /verysilent /sp- /suppressmsgboxes
C:\vc.exe /quiet /norestart

# Signing binaries
Bcdedit.exe -set TESTSIGNING ON
Restart-Computer
