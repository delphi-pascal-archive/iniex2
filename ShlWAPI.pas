unit ShlWAPI;

interface

function PathAddBackslash(pszPath: PChar): Cardinal; stdcall;
function PathAddExtension(pszPath, pszExt: PChar): Cardinal; stdcall;
function PathAppend(pszPath, pszMore: PChar): Cardinal; stdcall;
function PathBuildRoot(szRoot: PChar; iDrive: Integer): Cardinal; stdcall;
function PathCanonicalize(pszBuffer, pszPath: PChar): Cardinal; stdcall;
function PathCombine(lpszDest, lpszDir, lpszFile: PChar): Cardinal; stdcall;
function PathCommonPrefix(lpszFile1, lpszFile2, lpszPath: PChar): Cardinal; stdcall;
function PathCompactPath(hDC: Cardinal;lpszPath: PChar;dx: Integer): Cardinal; stdcall;
function PathCompactPathEx(pszOut, pszSrc: PChar; cchMax: Integer; dwFlags: Cardinal): Cardinal; stdcall;
procedure PathCreateFromUrl(pszUrl, pszPath: PChar;pcchPath: Cardinal;dwReserved: cardinal); stdcall;
function PathFileExists(pszPath: PChar): Cardinal; stdcall;
function PathFindOnPath(pszPath, ppszOtherDirs: PChar): LongBool; stdcall;
function PathGetCharType(ch: Char): Cardinal; stdcall;
function PathGetDriveNumber(pszPath: PChar): Cardinal; stdcall;
function PathIsDirectory(pszPath: PChar): Cardinal; stdcall;
function PathIsDirectoryEmpty(pszPath: PChar): Cardinal; stdcall;
function PathIsLFNFileSpec(pszName: PChar): Cardinal; stdcall;
function PathIsNetworkPath(pszPath: PChar): Cardinal; stdcall;
function PathIsPrefix(pszPrefix, pszPath: PChar): Cardinal; stdcall;
function PathIsRelative(pszPath: PChar): Cardinal; stdcall;
function PathIsRoot(pszPath: PChar): Cardinal; stdcall;
function PathIsSameRoot(pszPath1, pszPath2: PChar): Cardinal; stdcall;
function PathIsSystemFolder(pszPath: PChar; dwAttrb: Cardinal): Cardinal; stdcall;
function PathIsUNC(pszPath: PChar): Cardinal; stdcall;
function PathIsUNCServer(pszPath: PChar): Cardinal; stdcall;
function PathIsUNCServerShare(pszPath: PChar): Cardinal; stdcall;
function PathIsURL(pszPath: PChar): Cardinal; stdcall;
function PathMakePretty(pszPath: PChar): Cardinal; stdcall;
function PathMakeSystemFolder(pszPath: PChar): Cardinal; stdcall;
function PathMatchSpec(pszFileParam, pszSpec: PChar): Cardinal; stdcall;
procedure PathQuoteSpaces(lpsz: PChar); stdcall;
///////////////////////////////
implementation
///////////////////////////////
const
    shlwapi_ = 'shlwapi.dll';

function PathAddBackslash;      external shlwapi_ name 'PathAddBackslashA';
function PathAddExtension;      external shlwapi_ name 'PathAddExtensionA';
function PathAppend;            external shlwapi_ name 'PathAppendA';
function PathBuildRoot;         external shlwapi_ name 'PathBuildRootA';
function PathCanonicalize;      external shlwapi_ name 'PathCanonicalizeA';
function PathCombine;           external shlwapi_ name 'PathCombineA';
function PathCommonPrefix;      external shlwapi_ name 'PathCommonPrefixA';
function PathCompactPath;       external shlwapi_ name 'PathCompactPathA';
function PathCompactPathEx;     external shlwapi_ name 'PathCompactPathExA';
procedure PathCreateFromUrl;    external shlwapi_ name 'PathCreateFromUrlA';
function PathFileExists;        external shlwapi_ name 'PathFileExistsA';
function PathFindOnPath;        external shlwapi_ name 'PathFindOnPathA';
function PathGetCharType;       external shlwapi_ name 'PathGetCharTypeA';
function PathGetDriveNumber;    external shlwapi_ name 'PathGetDriveNumberA';
function PathIsDirectory;       external shlwapi_ name 'PathIsDirectoryA';
function PathIsDirectoryEmpty;  external shlwapi_ name 'PathIsDirectoryEmptyA';
function PathIsLFNFileSpec;     external shlwapi_ name 'PathIsLFNFileSpecA';
function PathIsNetworkPath;     external shlwapi_ name 'PathIsNetworkPathA';
function PathIsPrefix;          external shlwapi_ name 'PathIsPrefixA';
function PathIsRelative;        external shlwapi_ name 'PathIsRelativeA';
function PathIsRoot;            external shlwapi_ name 'PathIsRootA';
function PathIsSameRoot;        external shlwapi_ name 'PathIsSameRootA';
function PathIsSystemFolder;    external shlwapi_ name 'PathIsSystemFolderA';
function PathIsUNC;             external shlwapi_ name 'PathIsUNCA';
function PathIsUNCServer;       external shlwapi_ name 'PathIsUNCServerA';
function PathIsUNCServerShare;  external shlwapi_ name 'PathIsUNCServerShareA';
function PathIsURL;             external shlwapi_ name 'PathIsURLA';
function PathMakePretty;        external shlwapi_ name 'PathMakePrettyA';
function PathMakeSystemFolder;  external shlwapi_ name 'PathMakeSystemFolderA';
function PathMatchSpec;         external shlwapi_ name 'PathMatchSpecA';
procedure PathQuoteSpaces;      external shlwapi_ name 'PathQuoteSpacesA';

end.
