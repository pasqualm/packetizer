#By BigTeddy 05 September 2011

#This script uses the .NET FileSystemWatcher class to monitor file events in folder(s).
#The advantage of this method over using WMI eventing is that this can monitor sub-folders.
#The -Action parameter can contain any valid Powershell commands.  I have just included two for example.
#The script can be set to a wildcard filter, and IncludeSubdirectories can be changed to $true.
#You need not subscribe to all three types of event.  All three are shown for example.
# Version 1.1


# rutes on estan els fitxers que llisten les aplicacions a monitoritzar
$monitor_file_preprod='F:\Programas\packetizer\fitxers_auxiliars\monitor_preprod.txt'
$monitor_file_prod='F:\Programas\packetizer\fitxers_auxiliars\monitor_prod.txt'
$monitor_file_referencia='F:\Programas\packetizer\fitxers_auxiliars\monitor_referencia.txt'
$monitor_file_funcadd_proves='F:\Programas\packetizer\fitxers_auxiliars\monitor_funcadd_proves.txt'
$monitor_file_funcadd_prod='F:\Programas\packetizer\fitxers_auxiliars\monitor_funcadd_prod.txt'

function monitoritza_dir 
(
[string]$entorn,
[string]$aplicacio,
[string]$ordre
)
{
    #echo "entorn: $entorn"
    #echo "ordre: $ordre"

    # Enter the root path you want to monitor.
    if ($entorn -eq 'preprod') {
        $folder = "F:\DeploymentSharePreProd\Applications\$aplicacio"
        $flagfile = "F:\Programas\packetizer\builds_preprod\$aplicacio.flg" 
    }
    Elseif ($entorn -eq 'prod')
    {
        $folder = "F:\DeploymentShare\Applications\$aplicacio"
        $flagfile = "F:\Programas\packetizer\builds_prod\$aplicacio.flg"
    }
    Elseif ($entorn -eq 'referencia')
    {
        $folder = "F:\DeploymentSharePreProd\Applications\$aplicacio"
        $flagfile = "F:\Programas\packetizer\builds_referencia\$aplicacio.flg"
    }
    Elseif ($entorn -eq 'funcadd_proves')
    {
        $folder = "F:\Programas\packetizer\funcionalitats_addicionals\proves\$aplicacio"
        $flagfile = "F:\Programas\packetizer\builds_funcadd_proves\$aplicacio.flg"
    }
    Elseif ($entorn -eq 'funcadd_prod')
    {
        $folder = "F:\Programas\packetizer\funcionalitats_addicionals\prod\$aplicacio"
        $flagfile = "F:\Programas\packetizer\builds_funcadd_prod\$aplicacio.flg"
    }
    else
    {
        echo "El parametre entorn ha de valdre referencia, preprod, prod, funcadd_proves o funcadd_prod"
        exit
    }
    if (($ordre -ne 'subscribe') -and ($ordre -ne 'unsubscribe')) {
        echo "El ordre ha de valdre subscribe o unsubscribe"
        exit
    }

    # echo "folder:   $folder"
    # echo "flagfile: $flagfile"
    #exit

    if (-Not (Test-Path $folder)) {
        echo "El path a l'aplicació no existeix: " $folder
        exit
    }
    
    if ($ordre -eq 'subscribe') {
        $filter = '*.*'  # You can enter a wildcard filter here.

        # In the following line, you can change 'IncludeSubdirectories to $true if required.                          
        $fsw = New-Object IO.FileSystemWatcher $folder, $filter -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'}

        # Here, all four events are registerd.  You need only subscribe to events that you need:

        Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated$entorn$aplicacio -MessageData $flagfile -Action {
        $name = $Event.SourceEventArgs.Name
        $changeType = $Event.SourceEventArgs.ChangeType
        $timeStamp = $Event.TimeGenerated
        Write-Host "The file '$name' was $changeType at $timeStamp" -fore green 
        Out-File -FilePath $event.MessageData -Append -InputObject "The file '$name' was $changeType at $timeStamp"}

        Register-ObjectEvent $fsw Deleted -SourceIdentifier FileDeleted$entorn$aplicacio -MessageData $flagfile -Action {
        $name = $Event.SourceEventArgs.Name
        $changeType = $Event.SourceEventArgs.ChangeType
        $timeStamp = $Event.TimeGenerated
        Write-Host "The file '$name' was $changeType at $timeStamp" -fore red
        Out-File -FilePath $event.MessageData -Append -InputObject "The file '$name' was $changeType at $timeStamp"}

        Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged$entorn$aplicacio -MessageData $flagfile -Action {
        $name = $Event.SourceEventArgs.Name
        $changeType = $Event.SourceEventArgs.ChangeType
        $timeStamp = $Event.TimeGenerated
        Write-Host "The file '$name' was $changeType at $timeStamp" -fore white
        Out-File -FilePath $event.MessageData -Append -InputObject "The file '$name' was $changeType at $timeStamp"}

        Register-ObjectEvent $fsw Renamed -SourceIdentifier FileRenamed$entorn$aplicacio -MessageData $flagfile -Action {
        $name = $Event.SourceEventArgs.Name
        $changeType = $Event.SourceEventArgs.ChangeType
        $timeStamp = $Event.TimeGenerated
        Write-Host "The file '$name' was $changeType at $timeStamp" -fore yellow 
        Out-File -FilePath $event.MessageData -Append -InputObject "The file '$name' was $changeType at $timeStamp"}

        echo "Agregada monitoritzacio de: $folder"
        echo "en: $flagfile"

    }
    else
    {
        # To stop the monitoring, run the following commands:
        Unregister-Event FileDeleted$entorn$aplicacio
        Unregister-Event FileCreated$entorn$aplicacio
        Unregister-Event FileChanged$entorn$aplicacio
        Unregister-Event FileRenamed$entorn$aplicacio

        echo "Eliminada monitoritzacio de: $folder"
    }
}

# agrega (o lleva) les monitoritzacions de preprod
Get-Content $monitor_file_preprod | Foreach-Object {monitoritza_dir 'preprod' $_ 'subscribe'}
#Get-Content $monitor_file_preprod | Foreach-Object {monitoritza_dir 'preprod' $_ 'unsubscribe'}

# agrega (o lleva) les monitoritzacions de prod
Get-Content $monitor_file_prod | Foreach-Object {monitoritza_dir 'prod' $_ 'subscribe'}
#Get-Content $monitor_file_prod | Foreach-Object {monitoritza_dir 'prod' $_ 'unsubscribe'}

# agrega (o lleva) les monitoritzacions de referencia
Get-Content $monitor_file_referencia | Foreach-Object {monitoritza_dir 'referencia' $_ 'subscribe'}
#Get-Content $monitor_file_referencia | Foreach-Object {monitoritza_dir 'referencia' $_ 'unsubscribe'}

# agrega (o lleva) les monitoritzacions de funcionalitats addicionals de proves
Get-Content $monitor_file_funcadd_proves | Foreach-Object {monitoritza_dir 'funcadd_proves' $_ 'subscribe'}
#Get-Content $monitor_file_funcadd_proves | Foreach-Object {monitoritza_dir 'funcadd_proves' $_ 'unsubscribe'}

# agrega (o lleva) les monitoritzacions de funcionalitats addicionals de prod
Get-Content $monitor_file_funcadd_prod | Foreach-Object {monitoritza_dir 'funcadd_prod' $_ 'subscribe'}
#Get-Content $monitor_file_funcadd_prod | Foreach-Object {monitoritza_dir 'funcadd_prod' $_ 'unsubscribe'}
