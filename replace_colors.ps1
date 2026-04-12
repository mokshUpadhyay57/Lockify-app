$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | Where-Object { $_.FullName -notmatch "lib\\utils\\colors\.dart" }

$replacements = @(
    @{ Old = "Colors\.purple\.shade50"; New = "AppColors.purple50" },
    @{ Old = "Colors\.purple\.shade100"; New = "AppColors.purple100" },
    @{ Old = "Colors\.red\.shade50"; New = "AppColors.red50" },
    @{ Old = "Colors\.green\.shade50"; New = "AppColors.green50" },
    @{ Old = "Colors\.black87"; New = "AppColors.black87" },
    @{ Old = "Colors\.black54"; New = "AppColors.black54" },
    @{ Old = "Colors\.purple"; New = "AppColors.primaryPurple" },
    @{ Old = "Colors\.white"; New = "AppColors.white" },
    @{ Old = "Colors\.black"; New = "AppColors.black" },
    @{ Old = "Colors\.grey"; New = "AppColors.grey" },
    @{ Old = "Colors\.red"; New = "AppColors.errorRed" },
    @{ Old = "Colors\.green"; New = "AppColors.onlineGreen" },
    @{ Old = "Colors\.orange"; New = "AppColors.warningOrange" }
)

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $originalContent = $content
    $changed = $false
    
    foreach ($rep in $replacements) {
        if ($content -match $rep.Old) {
            $content = $content -replace $rep.Old, $rep.New
            $changed = $true
        }
    }
    
    if ($changed) {
        if ($content -notmatch "import ['""]package:lockify/utils/colors\.dart['""];") {
            # Try to add after the last package import
            if ($content -match "(?s)(.*import 'package:.*';)(.*)") {
                $content = $content -replace "(?s)(.*import 'package:.*';)(.*)", "`$1`r`nimport 'package:lockify/utils/colors.dart';`$2"
            } elseif ($content -match "(?s)(.*import '.*';)(.*)") {
                 $content = $content -replace "(?s)(.*import '.*';)(.*)", "`$1`r`nimport 'package:lockify/utils/colors.dart';`$2"
            } else {
                $content = "import 'package:lockify/utils/colors.dart';`r`n" + $content
            }
        }
        [System.IO.File]::WriteAllText($file.FullName, $content)
        Write-Host "Updated $($file.FullName)"
    }
}
