package com.dji.simulatorDemo;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;

public class ViewActivity extends Activity implements View.OnClickListener {

    private SQLiteDatabase dbWriter;
    private EditText roll;
    private EditText pitch;
    private EditText throttle;
    private EditText yaw;
    private EditText delay;



    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_view);
        Button delete_btn = (Button) findViewById(R.id.delete_btn);
        Button confirm_btn = (Button) findViewById(R.id.confirm_btn);
        roll = (EditText) findViewById(R.id.roll);
        pitch = (EditText) findViewById(R.id.pitch);
        throttle = (EditText) findViewById(R.id.throttle);
        yaw = (EditText) findViewById(R.id.yaw);
        delay = (EditText) findViewById(R.id.delay);
        delete_btn.setOnClickListener(this);
        confirm_btn.setOnClickListener(this);
        RouteDB routeDB = new RouteDB(this);
        dbWriter = routeDB.getWritableDatabase();
        loadContent();
    }

    private void loadContent(){
        Cursor cursor = null;
        cursor = dbWriter.query(RouteDB.TABLE_NAME, null, RouteDB.ID + "=" + getIntent().getStringExtra("ID"), null,
                null, null, null);
        cursor.moveToFirst();
        @SuppressLint("Range") Float flag1 = cursor.getFloat(cursor.getColumnIndex(RouteDB.ROLL));
        @SuppressLint("Range") Float flag2 = cursor.getFloat(cursor.getColumnIndex(RouteDB.PITCH));
        @SuppressLint("Range") Float flag3 = cursor.getFloat(cursor.getColumnIndex(RouteDB.THROTTLE));
        @SuppressLint("Range") Float flag4 = cursor.getFloat(cursor.getColumnIndex(RouteDB.YAW));
        @SuppressLint("Range") Float flag5 = cursor.getFloat(cursor.getColumnIndex(RouteDB.DELAY));

        roll.setText(flag1.toString());
        pitch.setText(flag2.toString());
        throttle.setText(flag3.toString());
        yaw.setText(flag4.toString());
        delay.setText(flag5.toString());

        if (cursor != null) {
            cursor.close();
        }
    }

    @SuppressLint("NonConstantResourceId")
    @Override
    public void onClick(View view) {
        switch (view.getId()){
            case R.id.delete_btn:
                deleteDate();
                finish();
                break;
            case R.id.confirm_btn:
                updateDB();
                finish();
                break;
        }
    }

    public void updateDB(){
        ContentValues cv = new ContentValues();
        cv.put(RouteDB.ROLL, Float.parseFloat(String.valueOf(roll.getText())));
        cv.put(RouteDB.PITCH, Float.parseFloat(String.valueOf(pitch.getText())));
        cv.put(RouteDB.THROTTLE, Float.parseFloat(String.valueOf(throttle.getText())));
        cv.put(RouteDB.YAW, Float.parseFloat(String.valueOf(yaw.getText())));
        cv.put(RouteDB.DELAY, Float.parseFloat(String.valueOf(delay.getText())));
        dbWriter.update(RouteDB.TABLE_NAME, cv, "_id=" + getIntent().getStringExtra("ID"), null);
    }

    public void deleteDate() {
        dbWriter.delete(RouteDB.TABLE_NAME,
                "_id=" + getIntent().getStringExtra("ID"), null);
    }
}

