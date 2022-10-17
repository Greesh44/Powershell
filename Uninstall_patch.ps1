function patch_uninstall{
param([string] $computername,
[string] $Hotfixid
)
$hotfixes = Get-WmiObject -ComputerName $computername -Class Win32_QuickFixEngineering | select hotfixid            
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
}   
} 
$computers=import-csv -Path "C:\Users\Administrator.DEMO\Desktop\input.csv" 
$output=$null
foreach($comp in $computers){
$server=$comp.server
$hotfixes=$comp.Hotfixes
if($hotfixes -like "*,*"){
$hotfixids=$hotfixes.Split(",")
    foreach($id in $hotfixids){
    $output+=patch_uninstall -computername $server -Hotfixid $id
    }
}
else{
$output+=patch_uninstall -computername $server -Hotfixid $hotfixes
}
}
$output