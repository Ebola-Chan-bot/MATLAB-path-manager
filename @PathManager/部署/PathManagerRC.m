function PathManagerRC
persistent SharedPathsTxt
if isempty(SharedPathsTxt)
	SharedPathsTxt=fullfile(getenv('ProgramData'),'MATLAB\共享路径.txt');
end
if isfile(SharedPathsTxt)
	path(path,fileread(SharedPathsTxt));
end