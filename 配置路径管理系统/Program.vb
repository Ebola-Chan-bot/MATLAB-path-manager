Imports System.IO
Imports System.IO.Path
Imports Microsoft.Win32
Imports System.Security.AccessControl

Module Program
	<Runtime.Versioning.SupportedOSPlatform("windows")>
	Sub Main(args As String())
		Select Case args(0)
			Case "安装"
				Dim MATLAB根目录 = args(1)
				Dim 字符串 As String = Combine(MATLAB根目录, "toolbox\local\private")
				Directory.CreateDirectory(字符串)
				Dim 部署目录 = Combine(AppDomain.CurrentDomain.SetupInformation.ApplicationBase, "..\部署")
				File.Copy(Combine(部署目录, "PathManagerRC.m"), Combine(字符串, "PathManagerRC.m"), True)
				Dim matlabrc = New FileStream(Combine(MATLAB根目录, "toolbox\local\matlabrc.m"), FileMode.Open)
				字符串 = New StreamReader(matlabrc).ReadToEnd
				If Not Text.RegularExpressions.Regex.IsMatch(字符串, "^PathManagerRC;$",Text.RegularExpressions.RegexOptions.Multiline ) Then
					Dim 写出字符串 As New Text.StringBuilder
					If Not {vbLf, vbCrLf}.Contains(字符串.Last) Then
						写出字符串.AppendLine()
					End If
					matlabrc.Seek(0, SeekOrigin.End)
					Call New StreamWriter(matlabrc) With {.AutoFlush = True}.Write(写出字符串.Append("PathManagerRC;").ToString)
					matlabrc.Close()
				End If
				File.Copy(Combine(部署目录, "替换savepath.m"), Combine(MATLAB根目录, "toolbox\matlab\general\savepath.m"), True)
				Dim 文件信息 As New FileInfo(Combine(MATLAB根目录, "toolbox\local\pathdef.m"))
				Dim 访问控制 = 文件信息.GetAccessControl
#If DEBUG Then
				Debugger.Launch()
#End If
				访问控制.SetAccessRule(New FileSystemAccessRule("Users", FileSystemRights.Modify, AccessControlType.Allow))
				文件信息.SetAccessControl(访问控制)
			Case "卸载"
				Dim 注册表键 As RegistryKey
				For Each 键名 In Registry.Users.GetSubKeyNames()
					注册表键 = Registry.Users.OpenSubKey(Combine(键名, "Environment"), True)
					If 注册表键 IsNot Nothing Then
						注册表键.DeleteValue("MATLABPATH", False)
					End If
				Next
				Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData)
				File.Delete(Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData), "MATLAB\共享路径.txt"))
				Dim MATLAB根目录 = args(1)
				File.Copy(Combine(AppDomain.CurrentDomain.SetupInformation.ApplicationBase, "..\部署\原版savepath.m"), Combine(MATLAB根目录, "toolbox\matlab\general\savepath.m"), True)
				Dim 子路径 = Combine(MATLAB根目录, "toolbox\local\matlabrc.m")
				File.WriteAllText(子路径, File.ReadAllText(子路径).Replace(vbCrLf & "PathManagerRC;", "").Replace(vbLf & "PathManagerRC;", ""))
				子路径 = Combine(MATLAB根目录, "toolbox\local\private")
				If Directory.Exists(子路径) Then
					If Directory.EnumerateFileSystemEntries(子路径).Count > 1 Then
						File.Delete(Combine(子路径, "PathManagerRC.m"))
					Else
						Directory.Delete(子路径, True)
					End If
				End If
		End Select
	End Sub
End Module
