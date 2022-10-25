<#CPU ,Memory  & Disk space (Used & total)usage report#>



<#Single Hostname or IP / Multiple Hostname or IP / input through txt file, as a input
 were it need to fetch all the information as per Task Name before that it need to query 
 for nslookup to match both IP -> hostname or hostname -> IP, then result should be either in csv or txt format
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
$global:Action_Performed=0
$outputdirectory="c:\temp1"
$outputpath="$outputdirectory\CPU_Memory_Disk_Details"
$date = Get-Date -Format 'yyyy_MM_dd'
$SuccessLogfile="$outputpath\" + $date + "_CPUMemoryDisk Log"
$ErrorLogfile="$outputpath\" + $date + "_Error Logs"
$outhtml="$outputpath\" + $date + "_CPU_Memory_DiskSpace_Report.html"
$outcsv="$outputpath\" + $date + "_CPU_Memory_DiskSpace_Report.csv"
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
<#$user="ds\bgreeshm-adm"
$pass="]2MxLF*3J3kx"
$pass1=ConvertTo-SecureString -String "$pass" -AsPlainText -Force -ErrorAction Stop     #Enter the password
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $user,$pass1#>

#$inputpath=$(Write-Host "Please provide the input filepath: " -ForegroundColor Yellow -NoNewline; Read-Host )
$inputpath="c:\users\bgreeshm-adm\desktop\ip.txt"
if(test-path -Path $inputpath){
$credential=Get-Credential -Message "Please Enter your domain credentials" 
$servers=get-content $inputpath|?{$_.trim() -ne ""}
if(![string]::IsNullOrWhiteSpace($servers)){

$out=foreach ($item in $servers) {
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
        [string]$msg="Resolving $Firstout1 with the ip $item";Write-Logs -Msg $msg -MsgType INFO -LogFile $SuccessLogfile
        if(![string]::IsNullOrWhiteSpace($item)){   
        if ( Test-Connection -ComputerName $item -Count 1 -ErrorAction SilentlyContinue ) {
        [string]$msg="Server $item is Reachable";Write-Logs -Msg $msg -MsgType INFO -LogFile $SuccessLogfile
            $global:reachable_count+=1
            $ps="Reachable"
            $avg = Get-WmiObject win32_processor -computername $item -Credential $credential |
                Measure-Object -property LoadPercentage -Average |
                Foreach {$_.Average}
            $mem = Get-WmiObject win32_operatingsystem -ComputerName $item -Credential $credential
            $totalmem=$mem|foreach{"{0:N2}" -f (($_.TotalVisibleMemorySize)/1mb)}
            $usedmem = $mem |Foreach {"{0:N2}" -f (($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)/1mb)}
            $freemem= $mem|foreach{"{0:N2}" -f (($_.FreePhysicalMemory)/1mb)}
            $usedmeminper=[math]::round(($usedmem/$totalmem)*100,2)
            $freememinper=[math]::round(($freemem/$totalmem)*100,2)
            $vol = Get-WmiObject -ComputerName $item -credential $credential -Class win32_logicaldisk|select deviceid
            [array]$drivesinfo=@()
            foreach( $i in $vol.deviceid){
                $vol1 = Get-WmiObject -ComputerName $item -credential $credential -Class win32_Volume -Filter "DriveLetter = '$i'"
                $total=([math]::Round(($vol1.capacity/100GB)*100,2))
                $free=([math]::Round(($vol1.FreeSpace/100GB)*100,2))
                $drivesinfo+=$i + " " + $free + " "+ "GB" + " " + "free of" + " " + $total + " " + "GB" 
            }

                [pscustomobject] [ordered] @{ # Only if on PowerShell V3
                    Giveninput = $item
                    Pinging=$ps
                    Hostname=$firstout1
                    IP=$SecondOut1
                    AverageCpu = "$avg" + " " + "%"
                    TotalMemory = "$totalmem" + " " + "GB"
                    'UsedMemory in (GB)'="$usedmem" + " " + "GB"
                    'FreeMemory in (GB)'="$freemem" + " " + "GB"
                    'UsedMemory in (%)'="$usedmeminper" + " " + "%"
                    'FreeMemory in (%)'="$freememinper" + " " + "%"
                     Volumes=$drivesinfo -join ","
                }

        $global:Action_Performed+=1
        [string]$msg="Successfully fetched inventory details from $item";Write-Logs -Msg $msg -MsgType INFO -LogFile $SuccessLogfile
        }
        else{
        [string]$msg="Server $item is Not Reachable";Write-Logs -Msg $msg -MsgType ERROR -LogFile $ErrorLogfile
        $global:notreachable_count+=1
        $ps="Not Reachable"
        [pscustomobject] [ordered] @{ # Only if on PowerShell V3
        Giveninput = $item
        Pinging=$ps
        Hostname=" "
        IP=" "
        AverageCpu = " "
        TotalMemory = " "
        'UsedMemory in (GB)'=" "
        'FreeMemory in (GB)'=" "
        'UsedMemory in (%)'=" "
        'FreeMemory in (%)'=" "
         Volumes=" "
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
        [pscustomobject] [ordered] @{ # Only if on PowerShell V3
        Giveninput = $item
        Pinging=$ps
        Hostname=" "
        IP=" "
        AverageCpu = " "
        TotalMemory = "  "
        'UsedMemory in (GB)'=" "
        'FreeMemory in (GB)'=" "
        'UsedMemory in (%)'=" "
        'FreeMemory in (%)'=" "
        Volumes=" "
        ErrorOccured=$errormessage
        }
        }
}
$out | Export-Csv -Path $outcsv -NoTypeInformation

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
<h1 style='color:darkblue'>CPU,Memory and Disk Utilization</h1>
<center>
<h3 style='text-align: left;'><b>$(get-date -Format 'dddd, MMMM dd, yyyy hh:mm:ss tt')</b></h3>
<h3 style='color:orange'>Server Reachable Details</h3>
<Table id=Header1>
<thead style='color:blue;'>
<tr>
<th>Total Server</th>
<th>Server Reachable</th>
<th>Action Performed</th>
<th>Server Not Reachable</th>
</tr>
</thead>
<tbody>
<tr>
<td>$($servers.count)</td>
<td>$($reachable_count)</td>
<td>$($Action_Performed)</td>
<td>$($notreachable_count)</td>
</tr></tbody>
</table>
<br><br>
<Table border=1 cellpadding=0 cellspacing=0 id=Header>
<thead style='color:blue;'>
<tr>
<th>Given Input</th>
<th>Ping Status</th>
<th>Host Name</th>
<th>IP Address</th>
<th>CPU Utilization</th>
<th>Total Memory</th>
<th>UsedMemory in (GB)</th>
<th>FreeMemory in (GB)</th>
<th>UsedMemory in (%)</th>
<th>FreeMemory in (%)</th>
<th>Volumes</th>
<th>Error Occured</th>
</tr>
</thead>
<tbody>"
$z += $out | %{
if($_.pinging -eq "Not Reachable"){
"<tr style='background-color:#F70E02;color:white;'>"
}
else{
"
<tr>"
}
"
<td>$($_.Giveninput)</td>
<td>$($_.Pinging)</td>
<td>$($_.hostname)</td>
<td>$($_.ip)</td>
<td>$($_.AverageCpu)</td>
<td>$($_.TotalMemory)</td>
<td>$($_.'UsedMemory in (GB)' ) </td>
<td>$($_.'FreeMemory in (GB)')</td>

"
if($_.'UsedMemory in (%)' -ge 80 -and $_.'UsedMemory in (%)' -le 90){
"<td style='background-color:#FFFF00;color:Black;'>$($_.'UsedMemory in (%)' ) </td>"
}elseif($_.'UsedMemory in (%)' -gt 90 ){
"<td style='background-color:#F70E02;color:Black;'>$($_.'UsedMemory in (%)' ) </td>"
}
else{
"<td>$($_.'UsedMemory in (%)' )</td>"
}
"<td>$($_.'FreeMemory in (%)')</td>"

"<td>$($_.Volumes)</td>"

if($_.Erroroccured -ne $null){
"<td style='background-color:red;color:white;'>$($_.erroroccured)</td>"
}
else{
"<td>$($_.erroroccured)</td>"
}

"
</tr>"
}
$z += "<tbody>
</table>
</div></div>
</body>
</html>
"

$z | Out-File $outhtml
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
$subject="CPU Memory DiskUsage Details"
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

