# Gera os sprites em pixel art do projeto a partir de "desenhos" em texto.
# Cada caractere e um pixel; a paleta diz qual cor cada caractere representa.
# "." e sempre transparente.
#
# Uso (na raiz do projeto):
#   powershell -ExecutionPolicy Bypass -File tools/generate_sprites.ps1
#
# Depois de rodar, abra o Godot para ele importar os PNGs novos.

Add-Type -AssemblyName System.Drawing

$OutputDir = Join-Path $PSScriptRoot "..\assets\sprites"
New-Item -ItemType Directory -Force $OutputDir | Out-Null


function New-Palette([string[]]$Entries) {
	# Cada entrada e "caractere=#rrggbb". Entradas repetidas sobrescrevem as anteriores.
	# Dictionary diferencia maiusculas de minusculas ("H" e "h" sao cores diferentes).
	$palette = [System.Collections.Generic.Dictionary[string, System.Drawing.Color]]::new()
	foreach ($entry in $Entries) {
		$key = $entry.Substring(0, 1)
		$hex = $entry.Substring(3)
		$palette[$key] = [System.Drawing.Color]::FromArgb(
			255,
			[Convert]::ToInt32($hex.Substring(0, 2), 16),
			[Convert]::ToInt32($hex.Substring(2, 2), 16),
			[Convert]::ToInt32($hex.Substring(4, 2), 16)
		)
	}
	return ,$palette
}


# Desenha uma parte (lista de linhas) dentro de um quadro da folha de sprites.
function Draw-Part($Bitmap, $Palette, [string[]]$Rows, [int]$FrameX, [int]$FrameY, [int]$Width, [int]$RowOffset) {
	for ($y = 0; $y -lt $Rows.Count; $y++) {
		$row = $Rows[$y]
		if ($row.Length -ne $Width) {
			throw "Linha com tamanho errado ($($row.Length) em vez de $Width): '$row'"
		}

		for ($x = 0; $x -lt $Width; $x++) {
			$char = [string]$row[$x]
			if ($char -eq ".") {
				continue
			}
			if (-not $Palette.ContainsKey($char)) {
				throw "Caractere '$char' nao existe na paleta"
			}
			$Bitmap.SetPixel($FrameX + $x, $FrameY + $RowOffset + $y, $Palette[$char])
		}
	}
}


function Save-Bitmap($Bitmap, [string]$FileName) {
	$path = Join-Path $OutputDir $FileName
	$Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
	$Bitmap.Dispose()
	Write-Host "Gerado: $path"
}


# ---------------------------------------------------------------------------
# Heroi (quadros de 16x24)
# Folha: colunas = parado, passo A, passo B, golpe
#        linhas  = baixo, cima, lado (direita; esquerda e espelhada no Godot)
# Cada quadro e montado com cabeca (linhas 0-9), tronco (10-15) e pernas (16-23).
# ---------------------------------------------------------------------------

$HeadDown = @(
	"...K.K.KK.K.K...",
	"..KHKHKHHKHKHK..",
	".KHHHHHHHHHHHHK.",
	".KHHhHHHHHHhHHK.",
	".KHRRRRRRRRRRHK.",
	".KHSSSSSSSSSSHK.",
	".KHSSKSSSSKSSHK.",
	".KHSSKSSSSKSSHK.",
	"..KSSSSSSSSSSK..",
	"...KsSSssSSsK..."
)

$HeadUp = @(
	"...K.K.KK.K.K...",
	"..KHKHKHHKHKHK..",
	".KHHHHHHHHHHHHK.",
	".KHHhHHHHHHhHHK.",
	".KHRRRRRRRRRRHK.",
	".KHHHHHHHHHHHHK.",
	".KHHHHHRRHHHHHK.",
	".KHHHHHRRHHHHHK.",
	"..KHHHHHHHHHHK..",
	"...KsSSSSSSsK..."
)

$HeadSide = @(
	"...K.K.K.K......",
	"..KHKHKHKHK.....",
	".KHHHHHHHHHK....",
	"KHHHHhHHHHHHK...",
	"KRRRRRRRRRRRK...",
	"RKHHHHSSSSSSK...",
	"RKHHHSSSSKSSK...",
	".KHHHSSSSKSSSK..",
	"..KHHSSSSSSSK...",
	"...KKsSSSSKK...."
)

$TorsoFront = @(
	"..KSKWWWWWWKSK..",
	"..KSKWWWWWWKSK..",
	"..KSKwWWWWwKSK..",
	"..KSKTTTTTTKSK..",
	"..KSKPPPPPPKSK..",
	"...KKPPPPPPKK..."
)

$TorsoFrontPunch = @(
	"..KSKWWWWWWKK...",
	"..KSKWWWWWWKSK..",
	"..KSKwWWWWwKSK..",
	"..KSKTTTTTTKSK..",
	"..KSKPPPPPPKSK..",
	"...KKPPPPPPKSK.."
)

$TorsoSide = @(
	"....KWWWWWWK....",
	"....KWWSSWWK....",
	"....KwWSSWwK....",
	"....KTTSSTTK....",
	"....KPPssPPK....",
	"....KPPKKPPK...."
)

$TorsoSidePunch = @(
	"....KWWWWWWK....",
	"....KWWWWWWKKKK.",
	"....KwWWWWWSSSSK",
	"....KTTTTTTKKKK.",
	"....KPPPPPPK....",
	"....KPPKKPPK...."
)

$LegsFrontIdle = @(
	"....KPPPPPPK....",
	"....KPPKKPPK....",
	"....KPPKKPPK....",
	"....KPpKKpPK....",
	"....KBBKKBBK....",
	"....KBBKKBBK....",
	"...KBBBKKBBBK...",
	"...KKKK..KKKK..."
)

$LegsFrontStepA = @(
	"....KPPPPPPK....",
	"....KPPKKPPK....",
	"....KPpKKPPK....",
	"....KBBKKPPK....",
	"....KBBKKBBK....",
	"...KBBBKKBBK....",
	"...KKKK.KBBBK...",
	".........KKKK..."
)

$LegsFrontStepB = @(
	"....KPPPPPPK....",
	"....KPPKKPPK....",
	"....KPPKKpPK....",
	"....KPPKKBBK....",
	"....KBBKKBBK....",
	"....KBBKKBBBK...",
	"...KBBBK.KKKK...",
	"...KKKK........."
)

$LegsSideIdle = @(
	"....KPPPPPPK....",
	"....KPPPPPK.....",
	".....KPPPPK.....",
	".....KPPPPK.....",
	".....KBBBBK.....",
	".....KBBBBK.....",
	".....KBBBBBBK...",
	".....KKKKKKK...."
)

$LegsSideStepA = @(
	"....KPPPPPPK....",
	"...KPPPKKPPPK...",
	"..KPPK....KPPK..",
	"..KPK......KPK..",
	".KBBK......KBBK.",
	".KBBK......KBBBK",
	".KKKK......KKKKK",
	"................"
)

$LegsSideStepB = @(
	"....KPPPPPPK....",
	"....KPPKKPPK....",
	"...KPPK..KPPK...",
	"...KPK....KPK...",
	"...KBK....KBK...",
	"..KBBK....KBBK..",
	"..KKKK....KKKKK.",
	"................"
)

# Punho estendido para baixo (desenhado por cima das pernas, a partir da linha 16).
$FistDown = @(
	"..........KSSK..",
	"..........KSSK..",
	"...........KK..."
)

# Braco erguido para cima (desenhado por cima da cabeca, a partir da linha 1).
$FistUp = @(
	"...........KK...",
	"..........KSSK..",
	"..........KSSK..",
	"..........KSSK..",
	"...........KSK.."
)

$HeroBase = @(
	"K=#1a1420",  # contorno
	"H=#2b2f5a",  # cabelo
	"h=#4a5291",  # brilho do cabelo
	"S=#f2c29b",  # pele
	"s=#c98d6a",  # sombra da pele
	"R=#c8324b",  # faixa na cabeca
	"W=#e8e8f0",  # regata
	"w=#a9acc0",  # sombra da regata
	"T=#2aa198",  # faixa da cintura
	"P=#3b3f4f",  # calca
	"p=#272a36",  # sombra da calca
	"B=#6b4a2f"  # botas
)

# Forma Desperta: mesmo desenho, so trocando cores do cabelo e da faixa.
$HeroAwakened = $HeroBase + @(
	"H=#e8f4ff",
	"h=#8fe3ff",
	"T=#7fdcff"
)

function Build-HeroSheet([string[]]$Colors, [string]$FileName) {
	$palette = New-Palette $Colors
	$bitmap = New-Object System.Drawing.Bitmap 64, 72

	# Cada item: coluna, linha, cabeca, tronco, pernas, sobreposicao, linha da sobreposicao
	$frames = @(
		@(0, 0, $HeadDown, $TorsoFront, $LegsFrontIdle, $null, 0),
		@(1, 0, $HeadDown, $TorsoFront, $LegsFrontStepA, $null, 0),
		@(2, 0, $HeadDown, $TorsoFront, $LegsFrontStepB, $null, 0),
		@(3, 0, $HeadDown, $TorsoFrontPunch, $LegsFrontIdle, $FistDown, 16),

		@(0, 1, $HeadUp, $TorsoFront, $LegsFrontIdle, $null, 0),
		@(1, 1, $HeadUp, $TorsoFront, $LegsFrontStepA, $null, 0),
		@(2, 1, $HeadUp, $TorsoFront, $LegsFrontStepB, $null, 0),
		@(3, 1, $HeadUp, $TorsoFrontPunch, $LegsFrontIdle, $FistUp, 1),

		@(0, 2, $HeadSide, $TorsoSide, $LegsSideIdle, $null, 0),
		@(1, 2, $HeadSide, $TorsoSide, $LegsSideStepA, $null, 0),
		@(2, 2, $HeadSide, $TorsoSide, $LegsSideStepB, $null, 0),
		@(3, 2, $HeadSide, $TorsoSidePunch, $LegsSideIdle, $null, 0)
	)

	foreach ($frame in $frames) {
		$x = $frame[0] * 16
		$y = $frame[1] * 24
		Draw-Part $bitmap $palette $frame[2] $x $y 16 0
		Draw-Part $bitmap $palette $frame[3] $x $y 16 10
		Draw-Part $bitmap $palette $frame[4] $x $y 16 16
		if ($null -ne $frame[5]) {
			Draw-Part $bitmap $palette $frame[5] $x $y 16 $frame[6]
		}
	}

	Save-Bitmap $bitmap $FileName
}

Build-HeroSheet $HeroBase "hero.png"
Build-HeroSheet $HeroAwakened "hero_awakened.png"


# ---------------------------------------------------------------------------
# Invasor (16x16)
# ---------------------------------------------------------------------------

$Invader = @(
	"................",
	"..K..........K..",
	".KhK........KhK.",
	".KhhK......KhhK.",
	"..KhhKKKKKKhhK..",
	"...KMMMMMMMMK...",
	"..KMMMMMMMMMMK..",
	".KMMYYMMMMYYMMK.",
	".KMMYKMMMMKYMMK.",
	".KMMMMMMMMMMMMK.",
	".KmMMKKKKKKMMmK.",
	".KmMMKFKKFKMMmK.",
	"..KmMMMMMMMMmK..",
	"..KmmMMMMMMmmK..",
	"...KKmmmmmmKK...",
	"....KK....KK...."
)

$InvaderColors = New-Palette @(
	"K=#1a1420",
	"M=#7b3fa0",
	"m=#52286e",
	"h=#e8d9b0",
	"Y=#ffd23f",
	"F=#ffffff"
)

$bitmap = New-Object System.Drawing.Bitmap 16, 16
Draw-Part $bitmap $InvaderColors $Invader 0 0 16 0
Save-Bitmap $bitmap "invader.png"


# ---------------------------------------------------------------------------
# Esfera de ki (8x8)
# ---------------------------------------------------------------------------

$KiOrb = @(
	"..BBBB..",
	".BbbbbB.",
	"BbbccbbB",
	"BbccccbB",
	"BbccccbB",
	"BbbccbbB",
	".BbbbbB.",
	"..BBBB.."
)

$KiColors = New-Palette @(
	"B=#2f8fff",
	"b=#8fd8ff",
	"c=#ffffff"
)

$bitmap = New-Object System.Drawing.Bitmap 8, 8
Draw-Part $bitmap $KiColors $KiOrb 0 0 8 0
Save-Bitmap $bitmap "ki_orb.png"


# ---------------------------------------------------------------------------
# Impacto do soco (11x11)
# ---------------------------------------------------------------------------

$Impact = @(
	".....W.....",
	".....W.....",
	"..W..W..W..",
	"...W.Y.W...",
	"....YYY....",
	"WWYYYWYYYWW",
	"....YYY....",
	"...W.Y.W...",
	"..W..W..W..",
	".....W.....",
	".....W....."
)

$ImpactColors = New-Palette @(
	"W=#ffffff",
	"Y=#ffe066"
)

$bitmap = New-Object System.Drawing.Bitmap 11, 11
Draw-Part $bitmap $ImpactColors $Impact 0 0 11 0
Save-Bitmap $bitmap "impact.png"


# ---------------------------------------------------------------------------
# Esfera de energia inimiga (8x8): mesmo desenho da esfera de ki, outras cores.
# ---------------------------------------------------------------------------

$DarkOrbColors = New-Palette @(
	"B=#a02050",
	"b=#ff5a8a",
	"c=#ffe0ea"
)

$bitmap = New-Object System.Drawing.Bitmap 8, 8
Draw-Part $bitmap $DarkOrbColors $KiOrb 0 0 8 0
Save-Bitmap $bitmap "dark_orb.png"


# ---------------------------------------------------------------------------
# Vigia (16x16): inimigo que flutua e atira de longe.
# ---------------------------------------------------------------------------

$Watcher = @(
	"................",
	".....KKKKKK.....",
	"...KKVVVVVVKK...",
	"..KVVVVVVVVVVK..",
	".KVVKKKKKKKKVVK.",
	".KVKEEEEEEEEKVK.",
	"KVVKEEERREEEKVVK",
	"KVVKEERKKREEKVVK",
	"KVVKEERKKREEKVVK",
	"KVVKEEERREEEKVVK",
	".KVKEEEEEEEEKVK.",
	".KvVKKKKKKKKVvK.",
	"..KvVVVVVVVVvK..",
	"...KvKvKKvKvK...",
	"...Kv.Kv.vK.vK..",
	"....K..K.K...K.."
)

$WatcherColors = New-Palette @(
	"K=#1a1420",
	"V=#3e8e5a",
	"v=#2a6040",
	"E=#f4f4f4",
	"R=#d43a3a"
)

$bitmap = New-Object System.Drawing.Bitmap 16, 16
Draw-Part $bitmap $WatcherColors $Watcher 0 0 16 0
Save-Bitmap $bitmap "watcher.png"


# ---------------------------------------------------------------------------
# Mestre (16x24): ancião de manto verde com cajado.
# ---------------------------------------------------------------------------

$Elder = @(
	"................",
	"......KKKK...KK.",
	".....KWWWWK.KYYK",
	"....KWWWWWWKKYYK",
	"....KWSSSSWK.KK.",
	"....KSKSSKSK.KB.",
	"....KSSSSSSK.KB.",
	"....KWWssWWK.KB.",
	"...KGKWWWWKGKKB.",
	"..KGGKWWWWKGGSB.",
	"..KGGGKWWKGGGSB.",
	"..KGgGGKKGGgGKB.",
	"..KGgGGGGGGgGKB.",
	"..KSgGGYYGGgK.B.",
	"...KgGGGGGGgK.B.",
	"...KgGGGGGGgK.B.",
	"...KgGGGGGGgK.B.",
	"...KgGGGGGGgK.B.",
	"..KgGGGGGGGGgKB.",
	"..KgGGGGGGGGgKB.",
	"..KggGGGGGGggKB.",
	"..KKKKKKKKKKKKB.",
	"....KBK..KBK..B.",
	"....KKK..KKK..K."
)

$ElderColors = New-Palette @(
	"K=#1a1420",
	"W=#eeeeee",  # cabelo e barba
	"S=#e8b48f",
	"s=#b98466",
	"G=#3f6b45",  # manto
	"g=#2c4d31",
	"Y=#e0b84a",  # cinto e pedra do cajado
	"B=#7a5230"   # cajado e sandalias
)

$bitmap = New-Object System.Drawing.Bitmap 16, 24
Draw-Part $bitmap $ElderColors $Elder 0 0 16 0
Save-Bitmap $bitmap "elder.png"


# ---------------------------------------------------------------------------
# Colosso Rubro (24x24): chefe de teste.
# ---------------------------------------------------------------------------

$Colossus = @(
	"........................",
	"..KK................KK..",
	".KhhK..............KhhK.",
	".KhhhK............KhhhK.",
	"..KhhhK..........KhhhK..",
	"...KhhhKKKKKKKKKKhhhK...",
	"....KKMMMMMMMMMMMMKK....",
	"...KMMMMMMMMMMMMMMMMK...",
	"..KMMMMMMMMMMMMMMMMMMK..",
	"..KMMKKKMMMMMMMMKKKMMK..",
	"..KMMKYYKMMMMMMKYYKMMK..",
	"..KMMMKKMMMMMMMMKKMMMK..",
	"..KMMMMMMMMMMMMMMMMMMK..",
	"..KmMMKKKKKKKKKKKKMMmK..",
	"..KmMMKFKFKKKKFKFKMMmK..",
	"..KmMMMKKKKKKKKKKMMMmK..",
	".KMKmMMMLLLLLLLLMMMmKMK.",
	"KMMKmMMLLLLLLLLLLMMmKMMK",
	"KMMKmMMLLLLLLLLLLMMmKMMK",
	"KhKKmmMMLLLLLLLLMMmmKKhK",
	"...KmmmMMMMMMMMMMmmmK...",
	"...KmmmmKKKKKKKKmmmmK...",
	"..KmmmmK........KmmmmK..",
	"..KKKKKK........KKKKKK.."
)

$ColossusColors = New-Palette @(
	"K=#1a1420",
	"M=#b0303a",
	"m=#7a1e28",
	"L=#d9775a",  # barriga
	"h=#e8d9b0",  # chifres e garras
	"Y=#ffe14d",
	"F=#ffffff"
)

$bitmap = New-Object System.Drawing.Bitmap 24, 24
Draw-Part $bitmap $ColossusColors $Colossus 0 0 24 0
Save-Bitmap $bitmap "colossus.png"


# ---------------------------------------------------------------------------
# Itens: coracao (cura) e cristal de ki.
# ---------------------------------------------------------------------------

$Heart = @(
	".KK...KK.",
	"KRRK.KRRK",
	"KRWRKRRRK",
	"KRRRRRRRK",
	".KRRRRRK.",
	"..KRRRK..",
	"...KRK...",
	"....K...."
)

$HeartColors = New-Palette @(
	"K=#1a1420",
	"R=#e8364f",
	"W=#ffd0d8"
)

$bitmap = New-Object System.Drawing.Bitmap 9, 8
Draw-Part $bitmap $HeartColors $Heart 0 0 9 0
Save-Bitmap $bitmap "heart.png"

$KiCrystal = @(
	"...K...",
	"..KBK..",
	".KBWBK.",
	"KBWBBBK",
	"KBBBBbK",
	"KBBBbbK",
	".KBbbK.",
	"..KbK..",
	"...K..."
)

$KiCrystalColors = New-Palette @(
	"K=#1a1420",
	"B=#5ab8ff",
	"b=#2f7fd0",
	"W=#ffffff"
)

$bitmap = New-Object System.Drawing.Bitmap 7, 9
Draw-Part $bitmap $KiCrystalColors $KiCrystal 0 0 7 0
Save-Bitmap $bitmap "ki_crystal.png"


# ---------------------------------------------------------------------------
# Escudo da defesa (16x16): anel de energia em volta do heroi.
# ---------------------------------------------------------------------------

$Guard = @(
	"......BBBB......",
	"....BBWWWWBB....",
	"...BW......WB...",
	"..BW........WB..",
	".BW..........WB.",
	".BW..........WB.",
	"BW............WB",
	"BW............WB",
	"BW............WB",
	"BW............WB",
	".BW..........WB.",
	".BW..........WB.",
	"..BW........WB..",
	"...BW......WB...",
	"....BBWWWWBB....",
	"......BBBB......"
)

$GuardColors = New-Palette @(
	"B=#5ab8ff",
	"W=#d8f2ff"
)

$bitmap = New-Object System.Drawing.Bitmap 16, 16
Draw-Part $bitmap $GuardColors $Guard 0 0 16 0
Save-Bitmap $bitmap "guard.png"
