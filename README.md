如果你是本机的唯一MATLAB用户，你应该不需要本工具箱。本工具箱面对的是多用户计算机的管理员，帮助管理员配置MATLAB路径，以便多个用户可以互不干扰地使用同一份MATLAB安装。

本工具箱依赖 [.Net 6.0 桌面运行时](https://dotnet.microsoft.com/zh-cn/download/dotnet/thank-you/runtime-desktop-6.0.2-windows-x64-installer)，首次安装时可能会报错提示需要安装该运行时。
# 适用症状
MATLAB垃圾的多用户搜索路径管理机制已经被广大公用计算机管理员们诟病已久，并且至今没有表露出任何打算改进的意图，因此本工具箱前来解决此问题！如果你管理的公用计算机上安装了唯一一份MATLAB并且共享给多个用户使用，你可能会遇到以下症状：

出现大量红字报错，包括搜索路径找不到、弹出一大堆错误提示对话框提示找不到函数等等。报错后MATLAB大量功能无法正常使用。这是因为路径定义函数pathdef.m为只读。

MATLAB能够正常使用，但是出现大量橙字警告，提示一大堆搜索路径找不到或无法打开。这是因为某用户设置了他的私有路径，其他用户无法访问。

某些 File Exchange 上下载的第三方工具箱，希望在用户之间共享，但却只能为每个用户重新安装一次，非常麻烦。这是因为第三方工具箱默认安装在用户私有目录下，其他用户无法访问。
# 病因和疗法
根本原因是MATLAB的搜索路径管理系统设计之初根本没有考虑到多用户之间的共享、隔离功能。多用户之间常常需要共享某些内容，而隔离另一些内容。Windows操作系统对此已经做了非常好的明确规范，尽管很多应用开发者并不遵守：
- %ProgramFiles%，存放x64应用的只读文件。这些文件应该仅在安装过程中可写，日常使用中应当保持只读。通常在这里存放应用的可执行文件、多媒体素材等日常使用过程中不需要修改的文件。
- %ProgramFiles(x86)%，存放x86应用的只读文件。
- %ProgramData%，存放一般用户只读、管理员可写的数据。这里通常存放的是一些全局配置文件，管理员有权修改它们，希望被一般用户共享，但不希望一般用户随意修改它们。
- %PUBLIC%，存放所有用户可写的数据。
- %APPDATA%，每个用户专有的应用数据。这些数据仅由每个用户自己可写（除了管理员可读写所有用户数据），对这些数据的修改不会影响其它用户。

我们希望的搜索路径，应当由3部分组成：
- 内置和工具箱函数路径，这些路径应当仅在安装时允许修改，因此应放在%ProgramFiles%目录下
- 用户之间共享的第三方函数路径，这些路径应当只允许管理员修改，一般用户只能读取，因此应放在%ProgramData%目录下
- 用户自己使用的代码路径，这些路径应当允许用户自己修改，但是不应影响到其他用户，因此应放在%APPDATA%下。但是因为MATLAB恰好支持更方便的%MATLABPATH%环境变量，所以使用该变量实现用户私有路径。

而MATLAB是怎么做的呢？它彻底无视了上述规范，将上述三种路径通通存放在%ProgramFiles%的pathdef.m下。因为%ProgramFiles%被认为是只有在安装时才允许修改的，因此一般用户无法修改它，也就无法设置自己需要的路径。如果管理员修改了权限，允许一般用户修改它，那么任何一个用户的改动都会影响到其他用户，导致其他用户出现无法访问别人的私有目录的问题。

为了纠正这个问题，本工具箱需要管理员权限，对内置savepath和matlabrc函数行为进行更改，避免修改全局的pathdef。优化后，一般用户对搜索路径的修改只会影响自己，对其他人无影响；而管理员则可以明确指定对全局路径的修改，让所有用户共享某些路径。
# API目录
所有函数均在静态类@PathManager下，使用前需导入：
```MATLAB
import PathManager.*
```
[AddSharedPaths](#AddSharedPaths) 添加共享搜索路径

[InstallSharedAddon](#InstallSharedAddon) 安装共享附加功能

[ListSharedAddons](#ListSharedAddons) 列出当前所有共享的附加功能

[RemoveSharedPaths](#RemoveSharedPaths) 移除共享搜索路径

[Setup](#Setup) 安装搜索路径管理系统。需要提权。

[SharedPaths](#SharedPaths) 显示/设置共享搜索路径。

[Uninstall](#Uninstall) 卸载搜索路径管理系统。需要提权

[UninstallSharedAddon](#UninstallSharedAddon) 卸载指定名称/位置的共享附加功能。
# AddSharedPaths
添加共享搜索路径

语法：SP=AddSharedPaths(SP)

输入参数：SP，要添加的搜索路径。可以是字符串数组或分号分隔路径的单个字符串。已存在的路径会自动排除，不会重复添加。

输出参数：SP，添加后新的搜索路径，不会有重复项。

提示：请确保其他用户有权限访问指定的路径。不要指定系统保护目录或某用户私有目录。建议使用InstallSharedAddon避免权限问题。
# InstallSharedAddon
安装共享附加功能

本函数将工具箱或共享文件安装到共享目录（%ProgramData%\MATLAB），并添加到共享搜索路径，使得所有用户都可以使用它。
```MATLAB
AddonInfo=InstallSharedAddon(AddonPath)
```
使用本函数将共享的文件安装到所有用户均有读取权限、无修改权限的目录下；只有创建者有权修改，并在所有用户开始MATLAB会话时强制加载。
## 示例
```MATLAB
import PathManager.InstallSharedAddon
%为所有用户安装工具箱
InstallSharedAddon('C:\Users\vhtmf\Downloads\工具箱.mltbx')
%将指定目录内的代码安装到所有用户都可以访问的位置
InstallSharedAddon('C:\Users\vhtmf\Documents\MATLAB\共享代码')
%将某个文件安装到所有用户都可以访问的位置
InstallSharedAddon('C:\Users\vhtmf\Documents\MATLAB\MyFunction1.m')
InstallSharedAddon('C:\Users\vhtmf\Documents\MATLAB\MyFunction2.mlx')
InstallSharedAddon('C:\Users\vhtmf\Documents\MATLAB\MyFunction3.mexw64')
%将某个包安装到所有用户都可以访问的位置
InstallSharedAddon('C:\Users\vhtmf\Documents\MATLAB\+MyPackage')
%将某个类安装到所有用户都可以访问的位置
InstallSharedAddon('C:\Users\vhtmf\Documents\MATLAB\@MyClass')
```
## 输入参数
AddonPath，要安装的附加功能路径。可以是任意工具箱、文件或目录。
## 输出参数
AddonInfo，附加功能的摘要。如果是工具箱，将调用matlab.addons.install进行安装，并返回它的返回值；否则仅返回附加功能的名称。
# ListSharedAddons
列出当前所有共享的附加功能

语法：List=ListSharedAddons

输出参数：List，所有附加功能的安装路径一览表
# RemoveSharedPaths
移除共享搜索路径

语法：SP=RemoveSharedPaths(SP)

输入参数：SP，要移除的搜索路径。可以是字符串数组或分号分隔路径的单个字符串。移除原本就不存在的搜索路径也不会报错。

输出参数：SP，移除后剩余的搜索路径
# Setup
安装搜索路径管理系统。需要提权。

语法：PathManager.Setup

警告：安装操作将调用restoredefaultpath，将MATLAB搜索路径出厂化（已安装的附加功能不受影响），所有用户自定义搜索路径都会被删除。此操作将影响所有用户。
# SharedPaths
显示/设置共享搜索路径。
```MATLAB
import PathManager.SharedPaths
SharedPaths(New) %设置共享搜索路径。
Old=SharedPaths %返回当前共享搜索路径
```
## 输入参数
New，要设置的新路径，旧路径会被它删除覆盖。输入可以是字符串数组或分号分隔路径的单个字符串。
## 输出参数
Old，当前共享搜索路径。如果设置了新的，将返回新路径。
## 说明
共享搜索路径将在不同用户之间共享。无论用户设置了任何自定义搜索路径，都不会覆盖共享路径，而是在任何用户启动MATLAB时强制加载。

# Uninstall
卸载搜索路径管理系统。需要提权

语法: PathManager.Uninstall

警告：卸载操作将删除之前设置的所有用户私有搜索路径和共享搜索路径，将MATLAB搜索路径出厂化（已安装的附加功能不受影响）。此操作将影响所有用户。
# UninstallSharedAddon
卸载指定名称/位置的共享附加功能。

语法：UninstallSharedAddon(Addon)

输入参数：Addon，要卸载的附加功能的名称或安装位置。如果不是使用PathManager.InstallSharedAddon安装在默认位置的，必须指定完整路径；否则可以只输入名称。