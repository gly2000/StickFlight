package com.dji.simulatorDemo;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

import androidx.annotation.Nullable;

public class RouteDB extends SQLiteOpenHelper {

    public static final String TABLE_NAME = "routes";
    public static final String ID = "_id";
    public static final String ROLL = "roll";
    public static final String PITCH = "pitch";
    public static final String THROTTLE = "throttle";
    public static final String YAW = "yaw";
    public static final String DELAY = "delay";


    public RouteDB(@Nullable Context context) {
        super(context, "routes", null, 1);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL("CREATE TABLE "+ TABLE_NAME + "("
                    + ID + " INTEGER PRIMARY KEY AUTOINCREMENT,"
                    + ROLL + " FLOAT NOT NULL,"
                    + PITCH + " FLOAT NOT NULL,"
                    + THROTTLE + " FLOAT NOT NULL,"
                    + YAW + " FLOAT NOT NULL,"
                    + DELAY + " FLOAT NOT NULL)");
    }

    @Override
    public void onUpgrade(SQLiteDatabase sqLiteDatabase, int i, int i1) {

    }
}
