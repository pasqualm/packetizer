#

# fa la sincronitzacio de fitxers des d'un grup de carpetes locals a una carpeta remota seguint
#les parametritzacions marcades en el fitxer de configuracio
function folderSyncing
(
    [array]$localPaths,
    [string]$remotePath
)
{
    # carrega en variables dades del fitxer de configuracio
    $funcAddPkgs=$ConfigFile.config.packagesConfig.funcAdds.package
    $skipPackages=$ConfigFile.config.packagesConfig.skipPackages.package
    #Write-Host $funcAddPkgs
    #Write-Host $skipPackages

    # passa per totes les carpetes de que continguen paquets per fer el sync
    foreach( $localPath in $localPaths.folder) 
    { 
	    #Write-Host $localPath
        # revisa cada carpeta no buida del directoru local
	    $dir = dir $localPath | ?{$_.PSISContainer}
	    foreach ($d in $dir)
	    {
            # si el paquet esta en la llista de paquets a ometre passem d'ell
            if ($skipPackages -contains $d.Name) {
                continue
            }

            # verifiquem si el paquet es una funcionalitat adicional i segons si ho es o no li assignem la carpte remota que corresponga
		    if ($funcAddPkgs.Name -contains $d.Name) {
                $ndx = $funcAddPkgs.Name.IndexOf($d.Name)
                $subtype=$funcAddPkgs.type[$ndx]
                $destFolder="$remotePath\func_add\$subtype\$($d.Name)"
            }
            else {
                $destFolder="$remotePath\perfil_base\$($d.Name)"
            }
            $origFolder="$localPath\$($d.Name)"
            #Write-Host origFolder: $origFolder
            #Write-Host destFolder: $destFolder
            doRobocopy -origFolder $origFolder -destFolder $destFolder
	    }
    } 
}

# executa un sync des d'una carpeta orige a una desti 
function doRobocopy
(
    [string]$origFolder,
    [string]$destFolder,
    [string]$forceArgs
)
{
    Write-Host `tSyncing "$origFolder" to "$destFolder"
    robocopy "$origFolder" "$destFolder" /MIR /FFT /Z /W:5 /NP /NJH /NJS /NFL /NDL /NC /NS
}

# Import configuration from file
[xml]$ConfigFile = Get-Content "F:\Programas\packetizer\fitxers_auxiliars\sync_conf.xml"

# fes la sincronitzacio de carpetes de proves
Write-Host BEGIN Syncing Development packages
folderSyncing -localPaths $ConfigFile.config.globalConfig.localPaths.evalPackages -remotePath $ConfigFile.config.globalConfig.remotePaths.folderEval
Write-Host END Syncing Development packages`n

# fes la sincronitzacio de carpetes de produccio
Write-Host BEGIN Syncing Production packages
folderSyncing -localPaths $ConfigFile.config.globalConfig.localPaths.prodPackages -remotePath $ConfigFile.config.globalConfig.remotePaths.folderProd
Write-Host END Syncing Production packages`n

exit
