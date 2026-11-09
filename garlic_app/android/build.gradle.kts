allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Algunos plugins piden androidx.core en su ultima version (1.18, que exige compileSdk 36 y AGP 8.9.1).
// Se fija una version compatible con el compileSdk 35 / AGP 8.7 de Flutter 3.29.
subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.15.0", "androidx.core:core-ktx:1.15.0")
        }
    }
}
