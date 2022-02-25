classdef(Abstract,Sealed)PathManager
	properties(Constant,Access=private)
		MatlabDataDirectory=fullfile(getenv('ProgramData'),'MATLAB');
		SharedPathsTxt=fullfile(PathManager.MatlabDataDirectory,'共享路径.txt')
		Executable=fullfile(fileparts(mfilename("fullpath")),'net6.0\配置路径管理系统.exe');
		PS=pathsep
	end
	methods(Static)
		function Setup
			% 安装搜索路径管理系统。需要提权。依赖 .Net 6.0 桌面运行时，若未安装，首次启动时可能出错，提示需要安装。
			% 语法：PathManager.Setup
			% 警告：安装操作将调用restoredefaultpath，将MATLAB搜索路径出厂化（已安装的附加功能不受影响），所有用户自定义搜索路径都会被删除。此操作将影响所有用户。
			CurrentPaths=path;
			restoredefaultpath;
			MatlabSavepath;
			system(sprintf('"%s" %s "%s"',PathManager.Executable,'安装',matlabroot),'-runAsAdmin');
			clear savepath
			path(CurrentPaths);
		end
		function Uninstall(UninstallSharedAddons)
			% 卸载搜索路径管理系统。需要提权
			% 语法：PathManager.Uninstall(UninstallSharedAddons)
			% 输入参数：UninstallSharedAddons(1,1)logical=false，指示是否要删除已安装的共享附加功能
			% 警告：卸载操作将删除之前设置的所有用户私有搜索路径和共享搜索路径，将MATLAB搜索路径出厂化（已安装的附加功能不受影响）。此操作将影响所有用户。
			arguments
				UninstallSharedAddons=false
			end
			if UninstallSharedAddons
				SharedAddons=PathManager.ListSharedAddons;
				[~,Names]=fileparts(SharedAddons);
				IsToolbox=ismember(Names,matlab.addons.installedAddons().Name);
				ToUninstall=Names(IsToolbox);
				for T=1:numel(ToUninstall)
					matlab.addons.uninstall(ToUninstall(T));
				end
				MATLAB.General.Delete(SharedAddons(~IsToolbox));
			end
			system(sprintf('"%s" %s "%s"',PathManager.Executable,'卸载',matlabroot),'-runAsAdmin');
			clear savepath
		end
		function SP=SharedPaths(SP)
			% 显示/设置共享搜索路径。
			% # 语法：
			% import PathManager.SharedPaths
			% SharedPaths(New) %设置共享搜索路径。
			% Old=SharedPaths %返回当前共享搜索路径
			% # 输入参数
			% New，要设置的新路径，旧路径会被它删除覆盖。输入可以是字符串数组或分号分隔路径的单个字符串。
			% # 输出参数
			% Old，当前共享搜索路径。如果设置了新的，将返回新路径。
			% # 说明
			% 共享搜索路径将在不同用户之间共享。无论用户设置了任何自定义搜索路径，都不会覆盖共享路径，而是在任何用户启动MATLAB时强制加载。
			if nargin
				SP=char(join(SP,PathManager.PS));
				if SP(1)==PathManager.PS
					SP(1)=[];
				end
				if SP(end)==PathManager.PS
					SP(end)=[];
				end
				if ~isfolder(PathManager.MatlabDataDirectory)
					mkdir(PathManager.MatlabDataDirectory);
				end
				Fid=fopen(PathManager.SharedPathsTxt,"wt");
				fwrite(Fid,SP,'char');
				fclose(Fid);
			elseif isfile(PathManager.SharedPathsTxt)
				SP=fileread(PathManager.SharedPathsTxt);
			else
				SP='';
			end
		end
		function SP=AddSharedPaths(SP)
			% 添加共享搜索路径
			% 语法：SP=AddSharedPaths(SP)
			% 输入参数：SP，要添加的搜索路径。可以是字符串数组或分号分隔路径的单个字符串。已存在的路径会自动排除，不会重复添加。
			% 输出参数：SP，添加后新的搜索路径，不会有重复项。
			% 提示：请确保其他用户有权限访问指定的路径。不要指定系统保护目录或某用户私有目录。建议使用InstallSharedAddon避免权限问题。
			% See also PathManager.SharedPaths PathManager.InstallSharedAddon
			SP=split(SP,PathManager.PS);
			if isfile(PathManager.SharedPathsTxt)
				SP=union(SP,split(fileread(PathManager.SharedPathsTxt),PathManager.PS));
			end
			SP=string(join(SP(SP~=""),PathManager.PS));
			if isempty(SP)
				SP="";
			end
			if ~isfolder(PathManager.MatlabDataDirectory)
				mkdir(PathManager.MatlabDataDirectory);
			end
			Fid=fopen(PathManager.SharedPathsTxt,"wt");
			fwrite(Fid,SP,'char');
			fclose(Fid);
		end
		function SP=RemoveSharedPaths(SP)
			% 移除共享搜索路径
			% 语法：SP=RemoveSharedPaths(SP)
			% 输入参数：SP，要移除的搜索路径。可以是字符串数组或分号分隔路径的单个字符串。移除原本就不存在的搜索路径也不会报错。
			% 输出参数：SP，移除后剩余的搜索路径
			% See also PathManager.SharedPaths
			if isfile(PathManager.SharedPathsTxt)
				SP=string(join(setdiff(split(fileread(PathManager.SharedPathsTxt),PathManager.PS),split(SP,PathManager.PS)),PathManager.PS));
				if ismissing(SP)
					SP="";
				end
				Fid=fopen(PathManager.SharedPathsTxt,"wt");
				fwrite(Fid,SP,'char');
				fclose(Fid);
			end
		end
		function List=ListSharedAddons
			% 列出当前所有共享的附加功能
			% 语法：List=ListSharedAddons
			% 输出参数：List，所有附加功能的安装路径一览表
			% See also PathManager.InstallSharedAddon
			import System.IO.Directory.*
			SubDirectory=fullfile(PathManager.MatlabDataDirectory,'Toolboxes');
			List=cell(1,2);
			if isfolder(SubDirectory)
				List{1}=string(GetDirectories(SubDirectory));
			end
			SubDirectory=fullfile(PathManager.MatlabDataDirectory,'共享文件');
			if isfolder(SubDirectory)
				List{2}=string(GetFileSystemEntries(SubDirectory));
			end
			List=string([List{:}]);
		end
		AddonInfo=InstallSharedAddon(AddonPath)
		function UninstallSharedAddon(Addon)
			% 卸载指定名称/位置的共享附加功能。
			% 语法：UninstallSharedAddon(Addon)
			% 输入参数：Addon，要卸载的附加功能的名称或安装位置。如果不是使用PathManager.InstallSharedAddon安装在默认位置的，必须指定完整路径；否则可以只输入名称。
			% See also PathManager.InstallSharedAddon PathManager.ListSharedAddons
			[Directory,Name]=fileparts(Addon);
			if Directory==""
				Installed=PathManager.ListSharedAddons;
				[Directory,InstalledName]=fileparts(Installed);
				Directory=Directory(strcmp(InstalledName,Name));
			end
			Addon=fullfile(Directory,Name);
			if ismember(Name,matlab.addons.installedAddons().Name)
				CurrentPaths=split(path,PathManager.PS);
				matlab.addons.uninstall(Name);
				PathManager.RemoveSharedPath(setdiff(CurrentPaths,split(path,PathManager.PS)));
			else
				if isfolder(Addon)
					PathManager.RemoveSharedPath(Addon);
					rmdir(Addon,'s');
				elseif isfile(Addon)
					delete(Addon);
				end
			end
		end
		function V=Version
			V.Me='1.0.1';
			V.MatlabExtension=MATLAB.Version;
			V.MATLAB='R2022a';
		end
	end
end