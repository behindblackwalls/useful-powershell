$file = "C:\path\to\your\file.txt"

# Get the file size
$fileSize = (Get-Item $file).length

# Overwrite the file with zeros
[Byte[]]$zeros = 0 * $fileSize
[System.IO.File]::WriteAllBytes($file, $zeros)

# Now delete the file
Remove-Item $file
