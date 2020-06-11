#Send-MailMessage -To "wellbersantos@hotmail.com" -From "mother-of-dragons@houseoftargaryen.net"  -Subject "Hey, Jon" -Body "Some important plain text!" -SmtpServer "201.23.105.84" -Port 587
param ([string]$aovivo,$siteaovivo)
$TimeStamp = get-date -f yyyy.MM.dd.hh:mm
$Source = "\\172.30.0.20\e$\sites\aovivo.integra.tv.br\website\"
$Destination = "C:\Sites\aovivo.integra.tv.br\website\" 

$iisAppPoolDotNetVersion = "v4.0"
$Logfile = "C:\$(gc env:computername).log"
$LogfileCopy = "C:\$(gc env:computername)-file.log"
$Location = Get-Location
$FolderPath = "C:\Sites\aovivo.integra.tv.br\website\"
$FileName = "netpoint.htm"

Function LogWrite{
   Param ([string]$logstring)

   Add-content $Logfile -value $logstring
}
if (!(Test-Path "C:\Sites\aovivo.integra.tv.br\website\netpoint.htm")){
	LogWrite "$TimeStamp - Healtcheck não existe, criando arquivo netpoint.htm"
	New-Item -itemType File -Path  $FolderPath -Name $FileName
	LogWrite "$TimeStamp - Healtcheck criado"
}
else {
	LogWrite "$TimeStamp - Healtcheck netpoint.htm existe"
}		


if ( $PSBoundParameters.ContainsKey('aovivo')){	
	Import-Module WebAdministration
	foreach ($I in $aovivo){
		#Import-Module WebAdministration
		LogWrite "$TimeStamp - Enviando dados de: $Source$I Para: $Destination$I"
		Robocopy /MIR $Source$I $Destination$I > $LogfileCopy
		LogWrite "$TimeStamp - Finalizado copia de dados de: $Source$I Para: $Destination$I"
		#check if the app pool exists
		if (!(Test-Path IIS:\AppPools\$I)){
			#create the app pool
			LogWrite "$TimeStamp - Criando AppPool para $I"
			cd IIS:\AppPools\
			$appPool = New-Item $I
			$appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
			#New-WebApplication -Name $I -Site 'Default Web Site' -PhysicalPath $Destination"\"$I  -ApplicationPool $I
			LogWrite "$TimeStamp - AppPool $I Criada"
			cd $Location
		}
	LogWrite "$TimeStamp - AppPool pra $I Existe"
	New-WebApplication -Name $I -Site 'Default Web Site' -PhysicalPath $Destination$I  -ApplicationPool $I -Force
	LogWrite "$TimeStamp - Transformado $I em Aplicação"


	}
}
elseif ( $PSBoundParameters.ContainsKey('siteaovivo')){
	Import-Module WebAdministration
	$site =$siteaovivo.Split("\.")
	$name = $site[0]
	if (!(Test-Path IIS:\AppPools\$siteaovivo)){
		#create the app pool
		LogWrite "$TimeStamp - Criando AppPool para $I"
		cd IIS:\AppPools\
		$appPool = New-Item $siteaovivo
		$appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
		#New-WebApplication -Name $I -Site 'Default Web Site' -PhysicalPath $Destination"\"$I  -ApplicationPool $I
		LogWrite "$TimeStamp - AppPool $I Criada"
		cd $Location
	}
	New-Website -Name $siteaovivo -Port 80 -HostHeader $siteaovivo -ApplicationPool $siteaovivo  -PhysicalPath $Destination$name
	New-WebBinding -Name $siteaovivo -IPAddress "*" -Port 80 -HostHeader "www.$siteaovivo"
	LogWrite "$TimeStamp - Enviando dados de: $Source$name Para: $Destination$name"
	Robocopy /MIR $Source$name $Destination$name > $LogfileCopy
	LogWrite "$TimeStamp - Finalizado copia de dados de: $Source Para: $Destination"
	LogWrite "$TimeStamp - Criado WebSite $siteaovivo"
	LogWrite "$TimeStamp - Criado HostHeader www.$siteaovivo"
}	
else{
	Write-Host
	Write-Host "Usage $PSCommandPath [OPTION] [TARGET]"
	Write-Host
	Write-Host "-aovivo:	Cria integra aovivo.integra.tv.br/[TARGET]"
	Write-Host
	Write-Host "-siteaovivo:	Cria site [TARGET] e copia conteudo usando o 1º nome antes do ponto"
	Write-Host "Ex: wellber.com.br copia wellber"
	Write-Host	
}