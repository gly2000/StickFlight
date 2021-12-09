package com.dji.simulatorDemo;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ContentValues;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;

public class SelectActivity extends Activity implements View.OnClickListener {

    private SQLiteDatabase dbWriter;
    private EditText roll;
    private EditText pitch;
    private EditText throttle;
    private EditText yaw;
    private EditText delay;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_select);
        Button return_btn = (Button) findViewById(R.id.return_btn);
        Button confirm_btn = (Button) findViewById(R.id.confirm_btn);
        roll = (EditText) findViewById(R.id.roll);
        pitch = (EditText) findViewById(R.id.pitch);
        throttle = (EditText) findViewById(R.id.throttle);
        yaw = (EditText) findViewById(R.id.yaw);
        delay = (EditText) findViewById(R.id.delay);
        return_btn.setOnClickListener(this);
        confirm_btn.setOnClickListener(this);
        RouteDB routeDB = new RouteDB(this);
        dbWriter = routeDB.getWritableDatabase();
    }

    @SuppressLint("NonConstantResourceId")
    @Override
    public void onClick(View view) {
        switch (view.getId()){
            case R.id.return_btn:
                finish();
                break;
            case R.id.confirm_btn:
                addDB();
                finish();
                break;
        }
    }

    public void addDB(){
        ContentValues cv = new ContentValues();
        cv.put(RouteDB.ROLL, Float.parseFloat(String.valueOf(roll.getText())));
        cv.put(RouteDB.PITCH, Float.parseFloat(String.valueOf(pitch.getText())));
        cv.put(RouteDB.THROTTLE, Float.parseFloat(String.valueOf(throttle.getText())));
        if(Float.parseFloat(String.valueOf(yaw.getText())) <= 180f){
            cv.put(RouteDB.YAW, Float.parseFloat(String.valueOf(yaw.getText())));
        }
        else{
            cv.put(RouteDB.YAW, Float.parseFloat(String.valueOf(yaw.getText())) - 360f);
        }
        cv.put(RouteDB.DELAY, Float.parseFloat(String.valueOf(delay.getText())));
        dbWriter.insert(RouteDB.TABLE_NAME, null, cv);
    }
}
