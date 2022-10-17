<#CPU ,Memory  & Disk space (Used & total)usage report#>



<#Single Hostname or IP / Multiple Hostname or IP / input through txt file, as a input
 were it need to fetch all the information as per Task Name before that it need to query 
 for nslookup to match both IP -> hostname or hostname -> IP, then result should be either in csv or txt format
 which could save it in C:\temp path, if path not exists then it need to create the same#>

$ErrorActionPreference = "Stop"
$global:reachable_count=0
$global:notreachable_count=0
$global:Action_Performed=0
$outputpath="c:\temp\CPU_Memory_Disk_Details"
if(!(test-path $outputpath)){
$osid=new-item -Path $outputpath -ItemType "directory"
}
$outcsv="$outputpath\CPU_Memory_Disk_Report.csv"
$outhtml="$outputpath\CPU_Memory_Disk_Report.html"

################ CREDENTIAL ######################
$user="ds\bgreeshm-adm"
$pass="]2MxLF*3J3kx"
$pass1=ConvertTo-SecureString -String "$pass" -AsPlainText -Force -ErrorAction Stop     #Enter the password
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $user,$pass1

#$inputpath=$(Write-Host "Please provide the input filepath: " -ForegroundColor Yellow -NoNewline; Read-Host )
$inputpath="c:\users\bgreeshm\desktop\ip.txt"
if(test-path -Path $inputpath){
$servers=get-content $inputpath
if(![string]::IsNullOrWhiteSpace($servers)){
    $out=foreach ($item in $servers) {
    if(![string]::IsNullOrWhiteSpace($item)){
    try {
	$ip=[system.net.dns]::gethostbyaddress($item)
	$hn=$ip.HostName

	$hostname=[system.net.dns]::gethostbyname($hn)

	$resolip=$hostname.addresslist.ipaddresstostring
	$resolhn=$hostname.hostname

        if($item -eq $resolip){ 
        if(![string]::IsNullOrWhiteSpace($item)){   
        if ( Test-Connection -ComputerName $item -Count 1 -ErrorAction SilentlyContinue ) {
            $global:reachable_count+=1
            $ps="Reachable"
            $avg = Get-WmiObject win32_processor -computername $item |
                Measure-Object -property LoadPercentage -Average |
                Foreach {$_.Average}
            $mem = Get-WmiObject win32_operatingsystem -ComputerName $item
            $totalmem=$mem|foreach{"{0:N2}" -f (($_.TotalVisibleMemorySize)/1mb)}
            $usedmem = $mem |Foreach {"{0:N2}" -f (($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)/1mb)}
            $freemem= $mem|foreach{"{0:N2}" -f (($_.FreePhysicalMemory)/1mb)}
            $usedmeminper=[math]::round(($usedmem/$totalmem)*100,2)
            #$freememinper=(100-$usedmeminper)
            $freememinper=[math]::round(($freemem/$totalmem)*100,2)
            $Disk=Get-WmiObject Win32_Volume -ComputerName $item -Filter "DriveLetter='c:'" 
            $totaldisk=$disk|Foreach {[math]::round($_.capacity/1Gb,2)}
            $freedisk = $Disk|Foreach {"{0:N2}" -f (($_.FreeSpace / $_.Capacity)*100)}
            $useddisk=$disk|foreach{"{0:N2}" -f(($_.capacity -$_.freespace)/1gb)}
            $useddiskinper=[math]::Round(($useddisk/$totaldisk)*100,2)
            $freediskinper=[math]::Round(($freedisk/$totaldisk)*100,2)

                [pscustomobject] [ordered] @{ # Only if on PowerShell V3
                    ComputerName = $item
                    Hostname=$hn
                    Pinging=$ps
                    AverageCpu = $avg
                    TotalMemory = $totalmem
                    'UsedMemory in (GB)'=$usedmem
                    'FreeMemory in (GB)'=$freemem
                    'UsedMemory in (%)'="$usedmeminper" + " " + "%"
                    'FreeMemory in (%)'="$freememinper" + " " + "%"
                    TotalDiskSpace=$totaldisk
                    'UsedDiskSpace in (GB)'=$useddisk
                    'FreeDiskSpace in (GB)'=$freedisk
                    'UsedDiskSpace in (%)'="$useddiskinper" + " " + "%"
                    'FreeDiskSpace in (%)'="$freediskinper" + " " + "%"
                }

            $global:Action_Performed+=1
            
        }
        else{
        $global:notreachable_count+=1
        $ps="Not Reachable"
        [pscustomobject] [ordered] @{ # Only if on PowerShell V3
        ComputerName = $item
        Hostname=" "
        Pinging=$ps
        AverageCpu = " "
        TotalMemory = " "
        'UsedMemory in (GB)'=" "
        'FreeMemory in (GB)'=" "
        'UsedMemory in (%)'=" "
        'FreeMemory in (%)'=" "
        TotalDiskSpace=" "
        'UsedDiskSpace in (GB)'=" "
        'FreeDiskSpace in (GB)'=" "
        'UsedDiskSpace in (%)'=" "
        'FreeDiskSpace in (%)'=" "
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
        ComputerName = $item
        Hostname=" "
        Pinging=" "
        AverageCpu = " "
        TotalMemory = "  "
        'UsedMemory in (GB)'=" "
        'FreeMemory in (GB)'=" "
        'UsedMemory in (%)'=" "
        'FreeMemory in (%)'=" "
        TotalDiskSpace=" "
        'UsedDiskSpace in (GB)'=" "
        'FreeDiskSpace in (GB)'=" "
        'UsedDiskSpace in (%)'=" "
        'FreeDiskSpace in (%)'=" "
        ErrorOccured=$errormessage
        }
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
<th> Host Name</th>
<th> IP Address</th>
<th> Ping Status</th>
<th> CPU Utilization</th>
<th> Total Memory</th>
<th> UsedMemory in (GB)</th>
<th> FreeMemory in (GB)</th>
<th> UsedMemory in (%)</th>
<th> FreeMemory in (%)</th>
<th> Total DiskSpace</th>
<th> Used DiskSpace in (GB)</th>
<th> Free DiskSpace in (GB)</th>
<th> Used DiskSpace in (%)</th>
<th> Free DiskSpace in (%)</th>
<th> Error Occured</th>
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
<td>$($_.hostname)</td>
<td>$($_.ComputerName)</td>
<td>$($_.Pinging)</td>
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
"<td>$($_.'FreeMemory in (%)')</td>
<td>$($_.TotalDiskSpace)</td>
<td>$($_.'UsedDiskSpace in (GB)' ) </td>
<td>$($_.'FreeDiskSpace in (GB)')</td>
"
if($_.'UsedDiskSpace in (%)' -ge 80 -and $_.'UsedDiskSpace in (%)' -le 90){
"<td style='background-color:#FFFF00;color:Black;'>$($_.'UsedDiskSpace in (%)' ) </td>"
}
elseif($_.'UsedDiskSpace in (%)' -gt 90 ){
"<td style='background-color:#F70E02;color:Black;'>$($_.'UsedDiskSpace in (%)' ) </td>"
}
else{
"<td>$($_.'UsedDiskSpace in (%)' ) </td>"
}
"<td>$($_.'FreeDiskSpace in (%)')</td>"

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
write-host "Please check $outputpath for results" -ForegroundColor green
$from ="bodumalla.greeshmitha@ascension-external.org"
$to="bodumalla.greeshmitha@ascension-external.org"
$stmpserver="mta.ascensionhealth.org"
$subject="CPU,Memory and DiskSpace Detail"
$bodyContent=$z
Send-MailMessage -SmtpServer $stmpserver -From $from -To $to -Subject $subject -Body $bodyContent -BodyAsHtml -Attachment @($outhtml,$outcsv)
Write-Host "Report Generated as $outcsv and $outhtml and being sent on email id $Mailto" -ForegroundColor Green
}
else{
write-host "Data not found in the Specified input file path $inputfilepath" -ForegroundColor Red
}
}
else{
write-host "Please provide the input file" -ForegroundColor Red
}