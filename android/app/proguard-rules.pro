# R8 removes Room's generated implementation classes, which crashes the app at
# start-up (androidx.work.impl.WorkDatabase, pulled in by the ads SDK).
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-dontwarn androidx.room.**
