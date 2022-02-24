function status=savepath(~)
persistent PS SharedPathsTxt SessionExclude AddonDirectory
if isempty(PS)
	PS=pathsep;
	SharedPathsTxt=fullfile(getenv('ProgramData'),'MATLAB\共享路径.txt');
	SessionExclude=split([perl('getphlpaths.pl',matlabroot) PS matlab.internal.language.ExcludedPathStore.getInstance.getExcludedPathEntry],PS);
	AddonDirectory=settings().matlab.addons.InstallationFolder;
end
Project=matlab.project.rootProject;
if isempty(Project)
	ProjectPaths=strings(1,0);
else
	ProjectPaths=string(unique(ProjectGraphTraverse(Project,strings(1,0))));
end
if isfile(SharedPathsTxt)
	SharedPaths=fileread(SharedPathsTxt);
else
	SharedPaths='';
end
PrivatePaths=split(path,PS);
System.Environment.SetEnvironmentVariable('MATLABPATH',string(join(setdiff(PrivatePaths(~startsWith(PrivatePaths,AddonDirectory.ActiveValue)),[split(SharedPaths,PS);SessionExclude;cellstr(ProjectPaths');{userpath}]),PS)),System.EnvironmentVariableTarget.User);
status=0;
end
function [ProjectPaths,KnownProjects] = ProjectGraphTraverse(Project,KnownProjects)
KnownProjects=[KnownProjects Project.RootFolder];
NumReferences=numel(Project.ProjectReferences);
ProjectPaths=cell(1,NumReferences);
for P=1:NumReferences
	PP=Project.ProjectReferences(P).Project;
	if ~ismember(PP.RootFolder,KnownProjects)
		[ProjectPaths{P},KnownProjects]=ProjectGraphTraverse(PP,KnownProjects);
	end
end
ProjectPaths=[ProjectPaths{:} arrayfun(@(PP)PP.File,Project.ProjectPath)];
end