On Error Resume Next

Dim executableName, softwareName, logFile, oWSH, ret

Set oWSH = CreateObject("WScript.Shell")
ret = -1
executableName = Left(WScript.Arguments(0), len(WScript.Arguments(0))-4)
softwareName = Left(executableName, len(executableName)-8)
logFile = oWSH.ExpandEnvironmentStrings("%TEMP%") & "\" & executableName & ".log"

oWSH.Run "Wbusy.exe ""Instal·lant software"" ""S'està realitzant la instal·lació del software " & softwareName & " en el seu ordinador.^ Quan acabe aquesta finestra es tancarà, si la tanca ara l'operació d'instal·lació no es veurà interrompuda.^Disculpe per les molèsties""  /marquee", 1, False
ret = oWSH.Run("""" & WScript.Arguments(0) & """ >" & logFile & " 2>&1", 0, True)

Select Case ret
  Case 0
    oWSH.Run "Wbusy.exe ""Instal·lant software"" ""L'operació d'instal·lació de " & softwareName & " ha finalitzat correctament.^Gràcies"" /Stop /timeout:5", 1, True
  Case 3010
    oWSH.Run "Wbusy.exe ""Instal·lant software"" ""L'operació d'instal·lació de " & softwareName & " ha finalitzat correctament, el sistema requereix un reinici per finalitzar la instal·lació^Gràcies"" /Stop", 1, False
  Case else
    oWSH.Run "Wbusy.exe ""Instal·lant software"" ""L'operació d'instal·lació de " & softwareName & " ha tornat un codi d'instal·lació " & ret & ", probablement aquesta ha fallat.^Revise el log " & logFile & " per més detalls  :("" /Stop", 1, False
End Select

WScript.Quit ret
