On Error Resume Next

Dim executableName, softwareName, logFile, oWSH, ret

Set oWSH = CreateObject("WScript.Shell")
ret = -1
executableName = Left(WScript.Arguments(0), len(WScript.Arguments(0))-4)
softwareName = Left(executableName, len(executableName)-8)
logFile = oWSH.ExpandEnvironmentStrings("%TEMP%") & "\" & executableName & ".log"

oWSH.Run "Wbusy.exe ""Instal�lant software"" ""S'est� realitzant la instal�laci� del software " & softwareName & " en el seu ordinador.^ Quan acabe aquesta finestra es tancar�, si la tanca ara l'operaci� d'instal�laci� no es veur� interrompuda.^Disculpe per les mol�sties""  /marquee", 1, False
ret = oWSH.Run("""" & WScript.Arguments(0) & """ >" & logFile & " 2>&1", 0, True)

Select Case ret
  Case 0
    oWSH.Run "Wbusy.exe ""Instal�lant software"" ""L'operaci� d'instal�laci� de " & softwareName & " ha finalitzat correctament.^Gr�cies"" /Stop /timeout:5", 1, True
  Case 3010
    oWSH.Run "Wbusy.exe ""Instal�lant software"" ""L'operaci� d'instal�laci� de " & softwareName & " ha finalitzat correctament, el sistema requereix un reinici per finalitzar la instal�laci�^Gr�cies"" /Stop", 1, False
  Case else
    oWSH.Run "Wbusy.exe ""Instal�lant software"" ""L'operaci� d'instal�laci� de " & softwareName & " ha tornat un codi d'instal�laci� " & ret & ", probablement aquesta ha fallat.^Revise el log " & logFile & " per m�s detalls  :("" /Stop", 1, False
End Select

WScript.Quit ret
