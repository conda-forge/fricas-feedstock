call build_env.bat

copy "%RECIPE_DIR%\build.sh" conda_build.sh
if errorlevel 1 exit 1

set "PREFIX=%PREFIX:\=/%"
set "BUILD_PREFIX=%BUILD_PREFIX:\=/%"
set "CONDA_PREFIX=%CONDA_PREFIX:\=/%"
set "SRC_DIR=%SRC_DIR:\=/%"
set MSYSTEM=UCRT64
set MSYS2_PATH_TYPE=inherit
set CHERE_INVOKING=1
bash -lc "./conda_build.sh"
if errorlevel 1 exit 1
