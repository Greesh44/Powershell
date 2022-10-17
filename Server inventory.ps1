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


$ErrorActionPreference = "Stop"
$outputpath="c:\temp\ServerInventoryDetails"
if(!(test-path $outputpath)){
$osid=new-item -Path $outputpath -ItemType "directory"
}
$outcsv="$outputpath\Server_Inventory_Report.csv"
$outhtml="$outputpath\Server_Inventory_Check.html"

################ CREDENTIAL ######################
$user="ds\bgreeshm-adm"
$pass="(gZxz<gh9\<w"
$pass1=ConvertTo-SecureString -String "$pass" -AsPlainText -Force -ErrorAction Stop     #Enter the password
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $user,$pass1

$inputpath=$(Write-Host "Please provide the input filepath: " -ForegroundColor Yellow -NoNewline; Read-Host )
#$inputpath="c:\users\bgreeshm\desktop\ip.csv"

if(test-path -Path $inputpath){
$global:reachable_count=0
$global:notreachable_count=0
$global:action_perfomed=0
$servers=Get-Content $inputpath
if(![string]::IsNullOrWhiteSpace($servers)){
$out=foreach($item in $servers){
if(![string]::IsNullOrWhiteSpace($item)){
try{
    $ip=[system.net.dns]::gethostbyaddress($item)
	$hn=$ip.HostName

	$hostname=[system.net.dns]::gethostbyname($hn)

	$resolip=$hostname.addresslist.ipaddresstostring
	$resolhn=$hostname.hostname

    if($item -eq $resolip){
    if(!([string]::IsNullOrWhiteSpace($item))){
    if(Test-Connection -ComputerName $item -Count 1 -Quiet){
    $global:reachable_count+=1
    $ps="Reachable"
    $sn=get-wmiobject -ComputerName $item -Class win32_computersystem
    $os=get-wmiobject -ComputerName $item -Class win32_operatingsystem 
    $lbu=Get-WmiObject -ComputerName $item -Class  win32_operatingsystem | select @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
    $cc=Get-WmiObject -ComputerName $item -Class win32_processor
    $vol1 = Get-WmiObject -ComputerName $item -Class win32_Volume -Filter "DriveLetter = 'C:'" |
    Select-object @{Name = "C capacity"; Expression = {“{0:N2}” -f  (($_.Capacity/100GB)*100) }}
    $vol2 = Get-WmiObject -ComputerName $item -Class win32_Volume -Filter "DriveLetter = 'C:'" |
    Select-object @{Name = "C Freespace"; Expression = {"{0:N2}" -f  (($_.FreeSpace /100GB)*100) }}
    $vol = Get-WmiObject  -ComputerName $item -Class win32_Volume  -Filter "DriveLetter = 'C:'" |
    Select-object @{Name = "C PercentFree"; Expression = {“{0:N2}” -f  (($_.FreeSpace / $_.Capacity)*100) } }
    $net=Get-WmiObject -ComputerName $item -Class Win32_NetworkAdapterConfiguration|select ipaddress
    $lpt=get-wmiobject -ComputerName $item -Class Win32_QuickFixEngineering |select @{Name="InstalledOn";Expression={$_.InstalledOn -as [datetime]}} | Sort-Object -Property Installedon | select-object -property installedon -last 1
    $tpm=$sn|foreach{[math]::round($_.Totalphysicalmemory/1Gb,2)}
        [Pscustomobject] @{
        Name=$item
        servername=$sn.Name
        Pinging=$ps
        OSVersion=$os.Version
        LastBootUpTime=$lbu.LastBootUpTime
        SerialNumber=$os.SerialNumber
        ServicePackMajorVersion=$os.ServicePackMajorVersion
        ServicePackMinorVersion=$os.ServicePackMinorVersion
        HardwareModel=$sn.Model
        CPUCore=$Cc.numberofcores
        'CDrive Capacity (GB)'=$vol1.'C capacity'
        'CDrive freespace (GB)'=$vol2.'C Freespace'
        'CDrive freespace (%)'=$vol.'C PercentFree' + " " + "%"
        CPUmodel=$cc.Name
        ProcessorSpeed=$cc.Name -replace '^.+@\s'
        NetworkIPAddress=$net.IPAddress[1]
        LastPatchTime=$lpt.InstalledOn
        TotalPhysicalMemory="$tpm" + " " + "GB"
        }
    $global:action_perfomed+=1

    } 
    else{
    $global:notreachable_count+=1
       $ps="Not Reachable"
       [Pscustomobject] @{
        Name=$item
        servername=" "
        Pinging=$ps
        OSVersion=" "
        LastBootUpTime=" "
        SerialNumber= " "
        ServicePackMajorVersion=" "
        ServicePackMinorVersion=" "
        HardwareModel=" "
        CPUCore=" "
        'CDrive Capacity (GB)'=" "
        'CDrive freespace (GB)'=" "
        'CDrive freespace (%)'=" "
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
        Name=$item
        servername=" "
        Pinging=" "
        OSVersion=" "
        LastBootUpTime=" "
        SerialNumber= " "
        ServicePackMajorVersion=" "
        ServicePackMinorVersion=" "
        HardwareModel=" "
        CPUCore=" "
        'CDrive Capacity (GB)'=" "
        'CDrive freespace (GB)'=" "
        'CDrive freespace (%)'=" "
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
<th>Name</th>
<th>Server Name</th>
<th>Pinging</th>
<th>OS Version</th>
<th>Last Boot UpTime</th>
<th>Serial Number</th>
<th>ServicePack Major Version</th>
<th>ServicePack Minor Version</th>
<th>Hardware Model</th>
<th>CPU Core</th>
<th>CDrive Capacity (GB)</th>
<th>CDrive freespace (GB)</th>
<th>CDrive freespace (%)</th>
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
<td>$($_.Name)</td>
<td>$($_.Servername)</td>
<td>$($_.pinging)</td>
<td>$($_.OSVersion)</td>
<td>$($_.LastBootUpTime)</td>
<td>$($_.SerialNumber)</td>
<td>$($_.ServicePackMajorVersion)</td>
<td>$($_.ServicePackMinorVersion)</td>
<td>$($_.HardwareModel)</td>
<td>$($_.CPUCore)</td>
<td>$($_.'CDrive Capacity (GB)')</td>
<td>$($_.'CDrive freespace (GB)')</td>
<td>$($_.'CDrive freespace (%)')</td>
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
write-host "Please check $outputpath for results" -ForegroundColor green
$from ="bodumalla.greeshmitha@ascension-external.org"
$to="bodumalla.greeshmitha@ascension-external.org"
$stmpserver="mta.ascensionhealth.org"
$subject="Server Inventory Details"
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