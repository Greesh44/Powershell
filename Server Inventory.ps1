
<#The script will status report for server Inventoty like Server Name,OS version,LastBootUpTime,
SerialNumber,Service Pack,Hardware Model,CPU core,Disk Details,CPUmodel,Processor Speed,
Network IP Address,Last Patch time,Total Physical Memory#>


<#Single Hostname or IP / Multiple Hostname or IP / input through txt file, as a input
were it need to fetch all the information as per Task Name before that it need to query
for nslookup to match both IP -> hostname or hostname -> IP, then result should be either in csv or txt 
format which could save it in C:\temp path, if path not exists then it need to create the same#>

<#Single Hostname or IP / Multiple Hostname or IP / input through txt file, as a input were it need 
to fetch all the information as per Task Name before that it need to query for nslookup
to match both IP -> hostname or hostname -> IP, then result should be either in csv or txt format
which could save it in C:\temp path, if path not exists then it need to create the same#>

try{
write-host "PLEASE ENTER YOUR DOMAIN CREDENTIALS" -ForegroundColor Yellow
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
$outputpath="$outputdirectory\ServerInventoryDetails"
$date = Get-Date -Format 'yyyy_MM_dd'
$SuccessLogfile="$outputpath\" + $date + "_Inventory Log"
$ErrorLogfile="$outputpath\" + $date + "_Error Logs"
$outhtml="$outputpath\" + $date + "_Server_Inventory_Report.html"
$outcsv="$outputpath\" + $date + "_Server_Inventory_Report.csv"
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
        $FirstOut=[system.net.dns]::gethostbyaddress($item)
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
    if(!([string]::IsNullOrWhiteSpace($item))){
    if(Test-Connection -ComputerName $item -Count 1 -Quiet){
    [string]$msg="Server $item is Reachable";Write-Logs -Msg $msg -MsgType INFO -LogFile $SuccessLogfile
    $global:reachable_count+=1
    $ps="Reachable"
    $sn=get-wmiobject -ComputerName $item  -credential $credential -Class win32_computersystem
    $os=get-wmiobject -ComputerName $item -credential $credential -Class win32_operatingsystem 
    $lbu=Get-WmiObject -ComputerName $item -credential $credential  -Class  win32_operatingsystem | select @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
    $cc=Get-WmiObject -ComputerName $item -credential $credential  -Class win32_processor
    $vol = Get-WmiObject -ComputerName $item -credential $credential -Class win32_logicaldisk|select deviceid
        [array]$drivesinfo=@()
        foreach( $i in $vol.deviceid){
        $vol1 = Get-WmiObject -ComputerName $item -credential $credential -Class win32_Volume -Filter "DriveLetter = '$i'"
        $total=([math]::Round(($vol1.capacity/100GB)*100,2))
        $free=([math]::Round(($vol1.FreeSpace/100GB)*100,2))
        $percentfree=([math]::Round(($vol1.Freespace/$vol1.Capacity)*100,2))
        $drivesinfo+=$i + " " + $free + " "+ "GB" + " " + "free of" + " " + $total + " " + "GB"
        }
    $net=Get-WmiObject -ComputerName $item -credential $credential -Class Win32_NetworkAdapterConfiguration|select ipaddress
    $lpt=get-wmiobject -ComputerName $item -credential $credential -Class Win32_QuickFixEngineering |select @{Name="InstalledOn";Expression={$_.InstalledOn -as [datetime]}} | Sort-Object -Property Installedon | select-object -property installedon -last 1
    $tpm=$sn|foreach{[math]::round($_.Totalphysicalmemory/1Gb,2)}
        [Pscustomobject] @{
        Giveninput=$item
        Pinging=$ps
        servername=$sn.Name
        IP=$SecondOut1
        Hostname=$Firstout1
        OSVersion=$os.Version
        LastBootUpTime=$lbu.LastBootUpTime
        SerialNumber=$os.SerialNumber
        ServicePackMajorVersion=$os.ServicePackMajorVersion
        ServicePackMinorVersion=$os.ServicePackMinorVersion
        HardwareModel=$sn.Model
        CPUCore=$Cc.numberofcores -join ","
        Volumes=$drivesinfo -join ","
        CPUmodel=$cc.Name -join ","
        ProcessorSpeed=$cc.Name -replace '^.+@\s' -join ","
        NetworkIPAddress=$net.IPAddress[1]
        LastPatchTime=$lpt.InstalledOn
        TotalPhysicalMemory="$tpm" + " " + "GB"
        }
    $global:action_perfomed+=1
    [string]$msg="Successfully fetched inventory details from $item";Write-Logs -Msg $msg -MsgType INFO -LogFile $SuccessLogfile
    } 
    else{
    [string]$msg="Server $item is Not Reachable";Write-Logs -Msg $msg -MsgType ERROR -LogFile $ErrorLogfile
    $global:notreachable_count+=1
       $ps="Not Reachable"
       [Pscustomobject] @{
        GivenInput=$item
        Pinging=$ps
        servername=" "
        IP=" "
        Hostname=" "
        OSVersion=" "
        LastBootUpTime=" "
        SerialNumber= " "
        ServicePackMajorVersion=" "
        ServicePackMinorVersion=" "
        HardwareModel=" "
        CPUCore=" "
        Volumes= " "
        CPUmodel=" "
        ProcessorSpeed=" "
        NetworkIPAddress=" "
        LastPatchTime=" "
        TotalPhysicalMemory=" "
        }
    
    }
    }
    }
    else{
    throw "Given $item is unable to resolve with the hostname $hn"
    }
    } 
catch{
$errormessage=$_.exception.message
    [Pscustomobject] @{
        GivenInput=$item
        Pinging=$ps
        servername=" "
        IP=" "
        Hostname=" "
        OSVersion=" "
        LastBootUpTime=" "
        SerialNumber= " "
        ServicePackMajorVersion=" "
        ServicePackMinorVersion=" "
        HardwareModel=" "
        CPUCore=" "
        Volumes=" "
        CPUmodel=" "
        ProcessorSpeed=" "
        NetworkIPAddress=" "
        LastPatchTime=" "
        TotalPhysicalMemory=" "
        ErrorOccured=$errormessage
        }
    

}
}
}
$out| export-csv -Path $outcsv -NoTypeInformation

$z="<html>
<head>
<style>
table{
font-size:12px
}
#Header{font-family:'Trebuchet MS', Arial, Helvetica, sans-serif;width:100%;border-collapse:collapse;}
#Header td, #Header th {font-size:14px;border:1px solid #DDDDDD;padding:5px 7px 5px 7px;}
#Header th {font-size:14px;text-align:left;padding-top:10px;padding-bottom:10px;background-color:#D6D6D6;color:blue;}
#Header tr.alt td {color:#000;background-color:#FAF2D3;}
#Header1{font-family:'Trebuchet MS', Arial, Helvetica, sans-serif;border-collapse:collapse;}
#Header1 td, #Header th {font-size:14px;border:1px solid #DDDDDD;padding:5px 7px 5px 7px;}
#Header1 th {font-size:14px;text-align:left;padding-top:10px;padding-bottom:10px;background-color:#D6D6D6;color:blue;}
#Header1 tr.alt td {color:#000;background-color:#FAF2D3;}
</style>
</head>
<body><div class ='col-md-12'>
<h3></h3>
<div class='col-md-12'>
<center>
<h1 style='color:darkblue'>SERVER INVENTORY REPORT</h1>
<center>
<h3 style='text-align: left;'><b>$(get-date -Format 'dddd, MMMM dd, yyyy hh:mm:ss tt')</b></h3>
<h3 style='color:orange'>Server Inventory Details</h3>
<Table id=Header1>
<thead style='color:blue;'>
<tr>
<th>Total Switch</th>
<th>Switch Reachable</th>
<th>Action Performed</th>
<th>Switch Not Reachable</th>
</tr>
</thead>
<tbody>
<tr>
<td>$($servers.count)</td>
<td>$($reachable_count)</td>
<td>$($action_perfomed)</td>
<td>$($notreachable_count)</td>
</tr></tbody>
</table>
<br><br>
<Table border=1 cellpadding=0 cellspacing=0 id=Header>
<thead style='color:blue;'>
<tr>
<th>Given Input</th>
<th>Pinging</th>
<th>Server Name</th>
<th>IP Address</th>
<th>Host Name</th>
<th>OS Version</th>
<th>Last Boot UpTime</th>
<th>Serial Number</th>
<th>ServicePack Major Version</th>
<th>ServicePack Minor Version</th>
<th>Hardware Model</th>
<th>CPU Core</th>
<th>Volumes</th>
<th>CPU Model</th>
<th>Processor Speed</th>
<th>Network IPAddress</th>
<th>Last Patch Date&Time</th>
<th>Total Physical Memory</th>
<th>Error Occured</th>
</tr>
</thead>
<tbody>"
$z += $out | %{
if($_.pinging -eq "Not Reachable"){
"<tr style='background-color:#F70E02;color:white;'>"
}
else{
"<tr>"
}
"
<td>$($_.Giveninput)</td>
<td>$($_.pinging)</td>
<td>$($_.Servername)</td>
<td>$($_.ip)</td>
<td>$($_.hostname)</td>
<td>$($_.OSVersion)</td>
<td>$($_.LastBootUpTime)</td>
<td>$($_.SerialNumber)</td>
<td>$($_.ServicePackMajorVersion)</td>
<td>$($_.ServicePackMinorVersion)</td>
<td>$($_.HardwareModel)</td>
<td>$($_.CPUCore)</td>
<td>$($_.volumes)</td>
<td>$($_.CPUmodel)</td>
<td>$($_.ProcessorSpeed )</td>
<td>$($_.NetworkIPAddress )</td>
<td>$($_.LastPatchTime )</td>
<td>$($_.TotalPhysicalMemory)</td>
"
if($_.Erroroccured -ne $null){
"<td style='background-color:red;color:white;'>$($_.erroroccured)</td>"
}
else{
"<td>$($_.erroroccured)</td>"
}
"

"
"
</tr>"
}
$z += "<tbody>
</table>
</div></div>
</body>
</html>
"
$z|Out-File $outhtml
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
$errormessage=$_.exception.message
[string] $msg= "Error: $errormessage" ;Write-Logs -Msg $msg -MsgType ERROR -LogFile $ErrorLogFile
}


############# SEND-EMAIL ####################
$from ="bodumalla.greeshmitha@ascension-external.org"
$to="bodumalla.greeshmitha@ascension-external.org"
$stmpserver="mta.ascensionhealth.org"
$subject="Server Inventory Details"
$outpaths=@($outhtml,$outcsv,$errorlogfile)
if((Test-Path -Path $outhtml) -and (Test-Path -Path $outcsv) ){
    $attachments = @($outhtml,$outcsv)
    $bodyContent= $z
}
elseif(test-path -Path $ErrorLogfile){
      $attachments=@($ErrorLogfile)
      $bodyContent=Get-Content $ErrorLogFile
}
else{
}



if(($attachments -contains $outhtml) -and ($attachments  -contains $outcsv)){
Send-MailMessage -SmtpServer $stmpserver -From $from -To $to -Subject $subject -Body $bodyContent -BodyAsHtml -Attachment $attachments
[string]$msg="Report Generated as $outcsv and $outhtml and being sent on email id $Mailto";Write-Logs -Msg $msg -MsgType INFO -LogFile $SuccessLogfile
}
else{
Send-MailMessage -SmtpServer $stmpserver -From $from -To $to -Subject $subject -Body $bodyContent -Attachment $attachments
[string]$msg="Report Generated as $Errorlogfile and being sent on email id $Mailto";Write-Logs -Msg $msg -MsgType INFO -LogFile $SuccessLogfile
}

