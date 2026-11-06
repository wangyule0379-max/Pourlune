# Ads' WorkManager 2.7.0 / Room 2.2.5 instantiate these through reflection.
# QA10 DEX retained the classes but removed these public no-arg constructors.
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
-keep class * extends androidx.work.InputMerger {
    public <init>();
}
