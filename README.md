# [RUSSIAN README](https://github.com/ILCKR/DDS-Resize-Tool/blob/main/README-RU.md)

# What is this?

- **DDS Resize Tool** - a tool for bulk, high-speed downsizing and recompression of DDS textures. Built using standard PowerShell and based on **Texconv**
- Capable of reducing texture size by up to 16x
- Best suited for textures that shared identical settings during their initial creation

# Requirements

1. **PowerShell 7** - [Microsoft](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5)
2. **Texconv** - [Latest](https://github.com/Microsoft/DirectXTex/releases/latest/download/texconv.exe)

# Usage

1. Run the `.ps1` file using **PowerShell 7**.
    1. The script automatically checks for `texconv.exe` in its directory. If not found, it will prompt you to drag and drop `texconv.exe` into the PowerShell window
2. Drag and drop the folder containing the textures you wish to process
3. Select the reduction scale (2x, 4x, 8x, 16x)
4. Wait for completion (progress is displayed)
5. Upon completion, the folder containing the converted textures will open automatically

### Important Notes

1. Settings are pre-configured to be universal, with one major caveat: **EACH TEXTURE MAY REQUIRE INDIVIDUAL AT PARAMETERS AND FILTERS**
2. All parameters used by Texconv are defined on line **112**:
    PowerShell
    ```... tc -nologo -if FANT -f $fmt -m 0 ...```
3. The script natively distinguishes between **Bump** and **Diffuse** textures.
4. Default compression formats: **BC1** for all `.dds` files, except for `bump.dds` which defaults to **BC3**

# Support

- Since I developed this script for a specific personal task, I cannot guarantee it will perform identically for everyone.
- As the code is fully open-source, you are free to use it however and wherever you like.
