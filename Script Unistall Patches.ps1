
write-host "PLEASE ENTER YOUR DOMAIN CREDENTIALS For EXCECUTING SCRIPT" -ForegroundColor Green
try{
$ErrorActionPreference = "Stop"
Function Clear-files{
param([array]$files)
    foreach($file in $files){
    if(Test-Path -Path $file){
    remove-item -Path $file -Force
    }
    }

}
Function Write-Logs {
	Param (
[string]$msg,
[string]$msgtype,
[string]$logfile
	)
If($MsgType -eq "ERROR") {[string]$MsgColor = "RED"}
If($MsgType -eq "INFO") {[string]$MsgColor = "GREEN"}
[string]$LogMsg = "$(Get-Date -Format 'yyyyMMdd HH:mm:ss') - $MsgType - $Msg"
$LogMsg|Out-File -FilePath $logfile -Append
Write-Host "$logmsg" -ForegroundColor $Msgcolor
}

####### CREATING VARIABLES #######
$global:reachable_count=0
$global:notreachable_count=0
$global:action_perfomed=0
$outputdirectory="c:\temp1"
$outputpath="$outputdirectory\UninstallHotfixes"
$date = Get-Date -Format 'yyyy_MM_dd'
$SuccessLogfile="$outputpath\" + $date + "_Hotfix Log"
$ErrorLogfile="$outputpath\" + $date + "_Error Logs"
$outhtml="$outputpath\" + $date + "_Hotfix_Uninstall_Report.html"
$outcsv="$outputpath\" + $date + "_HOtfix_Uninstall_Report.csv"
if(Test-Path $outputpath){
$paths=@($ErrorLogfile,$outhtml,$outcsv)
$clearfiles=Clear-files -files $paths
}
####### File Check ########

if(!(test-path $outputdirectory)){
$createtemp=new-item -Path $outputdirectory -ItemType "directory" 
     if(test-path -Path $outputdirectory){
        if(!(test-path -Path $outputpath)){
        $createsi=new-item -Path $outputpath -ItemType "directory"
             if(!(test-path -path $outputpath)){
             [string] $msg="Directory $outputpath not found"; Write-Logs -Msg $msg -MsgType ERROR -LogFile $ErrorLogFile
             }
        }

     }
}
else{
        if(!(test-path -Path $outputpath)){
        $createsi=new-item -Path $outputpath -ItemType "directory" 
             if(!(test-path -path $outputpath)){
             [string] $msg="Directory $outputpath not found"; Write-Logs -Msg $msg -MsgType ERROR -LogFile $ErrorLogFile
             }
        }
     
}
[string]$msg="Please check outputs in the $outputpath"; Write-Logs -Msg $msg -MsgType INFO -LogFile $SuccessLogfile

############### UNINSTALL PATCH #################
function patch_uninstall{
param([string] $computername,
[array] $Hotfixid
)
foreach($hotfix in $Hotfixid){
$hotfixes=Get-WmiObject -ComputerName $computername -Credential $credential -Class Win32_QuickFixEngineering|?{$_.hotfixid -eq $hotfix}
if(![string]::IsNullOrWhiteSpace($hotfixes)) {
    $hotfixID = $Hotfix.Replace("KB","")
    Write-host "Found the hotfix KB" + $HotfixID
    Write-Host "Uninstalling the hotfix"
    <#$UninstallString = "cmd.exe /c wusa.exe /uninstall /KB:$hotfixID /quiet /norestart"
    start-sleep 5
    ([WMICLASS]"\\$computername\ROOT\CIMV2:win32_process").Create($UninstallString) | out-null  #>          
    while (@(Get-Process wusa -computername $computername -ErrorAction SilentlyContinue).Count -ne 0) {
        Start-Sleep 3
        Write-Host "Waiting for update removal to finish ..."
    }
write-host "Completed the uninstallation of $hotfixID"
}
else {            
write-host "Given hotfix($hotfixID) not found"
}

}
<#$hotfixes = Get-WmiObject -ComputerName $computername -Credential $credential -Class Win32_QuickFixEngineering | select hotfixid            
if($hotfixes -match $hotfixID) {
    $hotfixID = $HotfixID.Replace("KB","")
    Write-host "Found the hotfix KB" + $HotfixID
    Write-Host "Uninstalling the hotfix"
    $UninstallString = "cmd.exe /c wusa.exe /uninstall /KB:$hotfixID /quiet /norestart"
    start-sleep 5
    ([WMICLASS]"\\$computername\ROOT\CIMV2:win32_process").Create($UninstallString) | out-null            
    while (@(Get-Process wusa -computername $computername -ErrorAction SilentlyContinue).Count -ne 0) {
        Start-Sleep 3
        Write-Host "Waiting for update removal to finish ..."
    }
write-host "Completed the uninstallation of $hotfixID"
}
else {            
write-host "Given hotfix($hotfixID) not found"
} #>  
} 

################ CREDENTIAL ######################
#$user="DS\DS-Runbook-SVC"
#$pass="A-y/Z#Kd"
<#$user="ds\bgreeshm-adm"
$pass="<vF2JMgrq!{+"
$pass1=ConvertTo-SecureString -String $pass -AsPlainText -Force -ErrorAction Stop
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList $user,$pass1#>
#$inputpath=$(Write-Host "Please provide the input filepath: " -ForegroundColor Yellow -NoNewline; Read-Host )
$inputpath="C:\Users\bgreeshm-adm\Desktop\ip.txt"
if(test-path -Path $inputpath){
#$credential=get-credential -Message "Please Enter your domain credentials"
$servers=Get-Content $inputpath|?{$_.trim() -ne ""}
if(![string]::IsNullOrWhiteSpace($servers)){
[string]$msg="Connection established Successfully for fetching info......";Write-Logs -Msg $msg -MsgType INFO -LogFile $SuccessLogfile
$out=foreach($item in $servers){
if(![string]::IsNullOrWhiteSpace($item)){
try{
    
    if([bool]($item -as [ipaddress])){
        $FirstOut=[system.net.dns]::gethostbyaddress("10.240.96.1")
	    $Firstout1=$FirstOut.HostName
	    $SecondOut=[system.net.dns]::gethostbyname($firstout1)
        $SecondOut1=$Secondout.addresslist.ipaddresstostring
    }
    elseif($item -like "*.*"){
        $SecondOut=[system.net.dns]::gethostbyname($item)
        $secondOut1=$Secondout.AddressList.ipaddresstostring

        $FirstOut=[system.net.dns]::gethostbyaddress($secondout1)
        $FirstOut1=$FirstOut.HostName
    }
    else{
    throw "Please provide FQDN/IP as a input"
    }

    if(($item -eq $SecondOut1) -or ($item -match $firstout1)){
    [string]$msg="Resolving $firstout1 with the ip $item";Write-Logs -Msg $msg -MsgType INFO -LogFile $SuccessLogfile
    $Response = 'Yes'
    $Id = $Null
    $inputList = @()
        Do 
        { 
        $Id = $(write-host " `n Please enter the hotfix to install on server $item :  " -NoNewline; Read-Host)

        $Response = $(write-host " `n Would you like to add additional hotfixes to this list? (yes/no) :  " -NoNewline; Read-Host)
        if(![string]::IsNullOrWhiteSpace($id)){
        $inputlist += $Id
        }
        }
        Until ($Response -eq 'No')
        patch_uninstall -computername $item -Hotfixid $inputList
        }
    else{
    throw "Given $item is unable to resolve with the hostname $hn"
    }
    } 
catch{
$errormessage=$_.exception.message
}
}
}

$out
}
else{
[string] $msg= "Data not found in the Specified input file path $inputfilepath" ;Write-Logs -Msg $msg -MsgType ERROR -LogFile $ErrorLogFile
}
}
else{
[string] $msg= "Please provide the input file" ;Write-Logs -Msg $msg -MsgType ERROR -LogFile $ErrorLogFile
}
}
catch{
$_.exception.message
}