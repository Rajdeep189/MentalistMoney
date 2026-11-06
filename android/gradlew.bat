@rem Minimal Gradle wrapper launcher (Windows)
@echo off
setlocal
set APP_HOME=%~dp0
set CLASSPATH=%APP_HOME%gradle\wrapper\gradle-wrapper.jar
if defined JAVA_HOME (set JAVACMD=%JAVA_HOME%\bin\java.exe) else (set JAVACMD=java.exe)
"%JAVACMD%" "-Xmx64m" "-Xms64m" %JAVA_OPTS% %GRADLE_OPTS% "-Dorg.gradle.appname=gradlew.bat" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*
endlocal
