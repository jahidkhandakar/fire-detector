// Root-level Gradle file: <project>/android/build.gradle.kts
plugins {
    // Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") apply false
}

// ✅ Repositories for all projects
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Configure build directory paths
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
