# Ads brings WorkManager 2.7 / Room 2.2.5. Their class-only consumer rules
# omit the no-arg constructors used by reflection; R8 full mode removes them.
# Keep those entry points without disabling shrinking or retaining whole SDKs.
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
-keep class * extends androidx.work.InputMerger {
    public <init>();
}
