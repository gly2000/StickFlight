package com.dji.simulatorDemo;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Adapter;
import android.widget.Button;
import android.widget.ListView;
import android.widget.Toast;

import androidx.recyclerview.widget.DividerItemDecoration;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.dji.simulatorDemo.beans.ControlData;

import java.util.Collections;
import java.util.Date;
import java.util.LinkedList;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

import dji.common.error.DJIError;
import dji.common.flightcontroller.virtualstick.FlightControlData;
import dji.common.flightcontroller.virtualstick.FlightCoordinateSystem;
import dji.common.flightcontroller.virtualstick.RollPitchControlMode;
import dji.common.flightcontroller.virtualstick.VerticalControlMode;
import dji.common.flightcontroller.virtualstick.YawControlMode;
import dji.common.util.CommonCallbacks;
import dji.sdk.products.Aircraft;

public class EditorActivity extends Activity implements OnClickListener {

    //获取控制器
    Aircraft aircraft = (Aircraft) DemoApplication.getProductInstance();

    //控件
    private RecyclerView recyclerView;
    private DataAdapter dataAdapter;
    private Button return_btn;
    private Button control_btn;
    private Button start_btn;
    private Button add_btn;

    //数据库
    private SQLiteDatabase dbReader;
    private Cursor cursor;

    //状态参数
    public boolean isEnableStick = false;
    public boolean isStartStickControl = false;

    //计时器
    private TimerTask sendVirtualStickDataTask;
    private Timer sendVirtualStickDataTimer;

    //stick默认数值
    private float roll = 0f;
    private float pitch = 0f;
    private float throttle = 1.2f;
    private float yaw = 0f;
    private float delay = 0f;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_task_main);

        //获取控件
        recyclerView = (RecyclerView) findViewById(R.id.route_list);
        return_btn = (Button) findViewById(R.id.return_btn);
        control_btn = (Button) findViewById(R.id.control_btn);
        start_btn = (Button) findViewById(R.id.start_btn);
        add_btn = (Button) findViewById(R.id.add_btn);

        //设置监听事件
        return_btn.setOnClickListener(this);
        start_btn.setOnClickListener(this);
        control_btn.setOnClickListener(this);
        add_btn.setOnClickListener(this);

        //获取数据库
        RouteDB routeDB = new RouteDB(this);
        dbReader = routeDB.getReadableDatabase();

        //处理recyclerView
        recyclerView.setLayoutManager(new LinearLayoutManager(this,
                LinearLayoutManager.VERTICAL, false));
        recyclerView.addItemDecoration(
                new DividerItemDecoration(this, DividerItemDecoration.VERTICAL));
        dataAdapter = new DataAdapter(new DataOperator() {
            @Override
            public void deleteData(ControlData controlData) {
                EditorActivity.this.deleteData(controlData);
            }
        });
        recyclerView.setAdapter(dataAdapter);

        dataAdapter.refresh(loadNotesFromDatabase());
    }

    //设置监听事件处理
    @SuppressLint("NonConstantResourceId")
    @Override
    public void onClick(View view) {
        switch (view.getId()) {
            case R.id.return_btn:
                checkReturn();
                break;
            case R.id.control_btn:
                setIsEnableStick();
                break;
            case R.id.start_btn:
                startVirtualStickControl();
                break;
            case R.id.add_btn:
                addNewRoute();
                break;
        }
    }

    public void checkReturn(){
        if(isStartStickControl){
            Toast toast = Toast.makeText(getApplicationContext(),"Please wait flight end!", Toast.LENGTH_LONG);
            toast.show();
        }else if(isEnableStick){
            Toast toast = Toast.makeText(getApplicationContext(),"Please quit virtual stick mode!", Toast.LENGTH_LONG);
            toast.show();
        }else{
            Intent i = new Intent(this, MainActivity.class);
            startActivity(i);
        }
    }

    public void setIsEnableStick(){
        //只有在停止飞行的情况下才能收回控制权
        if(!isStartStickControl){
            if(isEnableStick){
                //释放控制权
                endControl();
                //释放计时器
                disableControl();
                return_btn.setTextColor(0xFFFFFF);
                start_btn.setTextColor(0xFF0000);
                control_btn.setTextColor(0xFFFFFF);
                add_btn.setTextColor(0xFFFFFF);
                isEnableStick = false;
            }else{
                setControlMode();
                return_btn.setTextColor(0xFF0000);
                start_btn.setTextColor(0xFFFFFF);
                control_btn.setTextColor(0xFFFFFF);
                add_btn.setTextColor(0xFF0000);
            }
        }else{
            Toast toast = Toast.makeText(getApplicationContext(),"Please wait flight end!", Toast.LENGTH_LONG);
            toast.show();
        }

    }

    public void startVirtualStickControl(){
        //只有在获得无人机控制权后才能继续
        if(isEnableStick){
            isStartStickControl = true;
            return_btn.setTextColor(0xFF0000);
            start_btn.setTextColor(0xFF0000);
            control_btn.setTextColor(0xFF0000);
            add_btn.setTextColor(0xFF0000);
            virtualControl();
            setIsEnableStick();
        }else{
            Toast toast = Toast.makeText(getApplicationContext(),"Please start virtual stick mode!", Toast.LENGTH_LONG);
            toast.show();
        }
    }

    public void addNewRoute(){
        if(isStartStickControl){
            Toast toast = Toast.makeText(getApplicationContext(),"Please wait flight end!", Toast.LENGTH_LONG);
            toast.show();
        }else if(isEnableStick){
            Toast toast = Toast.makeText(getApplicationContext(),"Please quit virtual stick mode!", Toast.LENGTH_LONG);
            toast.show();
        }else{
            Intent i = new Intent(this, SelectActivity.class);
            startActivity(i);
        }
    }

    public void setControlMode() {
        aircraft.getFlightController()
                .setVirtualStickModeEnabled(true, djiError -> {
                    if (null == djiError) {
                        isEnableStick = true;
                        Log.e("virtual", "enable success");
                        aircraft.getFlightController().
                                setRollPitchCoordinateSystem(FlightCoordinateSystem.GROUND);
                        aircraft.getFlightController().
                                setVerticalControlMode(VerticalControlMode.POSITION);
                        aircraft.getFlightController().
                                setYawControlMode(YawControlMode.ANGLE);
                        aircraft.getFlightController().
                                setRollPitchControlMode(RollPitchControlMode.VELOCITY);
                    } else {
                        Log.e("virtual", "error = " + djiError.getDescription());
                    }
                });

        if (null == sendVirtualStickDataTimer) {
            sendVirtualStickDataTask = new TimerTask() {
                @Override
                public void run() {
                    if (isFlightControllerAvailable()) {
                        aircraft.getFlightController()
                                .sendVirtualStickFlightControlData(new FlightControlData(pitch, roll, yaw, throttle),
                                        new CommonCallbacks.CompletionCallback() {
                                            @Override
                                            public void onResult(DJIError djiError) {
                                            }
                                        });
                    } else {
                        Log.e("SendVirtualStickData", "isFlightControllerAvailable = false");
                    }
                }
            };
            sendVirtualStickDataTimer = new Timer();
            sendVirtualStickDataTimer.schedule(sendVirtualStickDataTask, 100, 200);
        } else {
            Log.e("dispatch", "isEnableStick = false");
        }
    }

    public void disableControl() {
        if (null != sendVirtualStickDataTimer) {
            if (sendVirtualStickDataTask != null) {
                sendVirtualStickDataTask.cancel();
            }
            sendVirtualStickDataTimer.cancel();
            sendVirtualStickDataTimer.purge();
            sendVirtualStickDataTimer = null;
            sendVirtualStickDataTask = null;
        }
    }

    public void endControl() {
        aircraft.getFlightController()
                .setVirtualStickModeEnabled(false, djiError -> {
                    if (null == djiError) {
                        isEnableStick = false;
                        Log.e("virtual", "disable success");
                    } else {
                        Log.e("virtual", "error = " + djiError.getDescription());
                    }
                });
    }

    @SuppressLint("Range")
    public void virtualControl() {
        cursor = dbReader.query(RouteDB.TABLE_NAME, null, null, null, null, null, null);
        cursor.moveToFirst();
        Integer step = 0;
        for (cursor.moveToFirst(); !cursor.isAfterLast(); cursor.moveToNext()) {
            step = step + 1;
            Toast toast = Toast.makeText(getApplicationContext(),"Step " + step.toString() + " is running", Toast.LENGTH_SHORT);
            toast.show();
            roll = cursor.getFloat(cursor.getColumnIndex(RouteDB.ROLL));
            pitch = cursor.getFloat(cursor.getColumnIndex(RouteDB.PITCH));
            throttle = cursor.getFloat(cursor.getColumnIndex(RouteDB.THROTTLE));
            yaw = cursor.getFloat(cursor.getColumnIndex(RouteDB.YAW));
            delay = cursor.getFloat(cursor.getColumnIndex(RouteDB.DELAY));
            Log.e("setSendData", "send = " + roll + " " + pitch + " " + throttle + " " + yaw);
            try {
                Thread.sleep((long) delay);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public List<ControlData> loadNotesFromDatabase() {
        if (dbReader == null) {
            return Collections.emptyList();
        }
        List<ControlData> result = new LinkedList<>();
        Cursor cursor = null;
        try {
            cursor = dbReader.query(RouteDB.TABLE_NAME, null, null, null, null, null, null);

            while (cursor.moveToNext()) {
                @SuppressLint("Range") long id = cursor.getLong(cursor.getColumnIndex(RouteDB.ID));
                @SuppressLint("Range") Float flag1 = cursor.getFloat(cursor.getColumnIndex(RouteDB.ROLL));
                @SuppressLint("Range") Float flag2 = cursor.getFloat(cursor.getColumnIndex(RouteDB.PITCH));
                @SuppressLint("Range") Float flag3 = cursor.getFloat(cursor.getColumnIndex(RouteDB.THROTTLE));
                @SuppressLint("Range") Float flag4 = cursor.getFloat(cursor.getColumnIndex(RouteDB.YAW));
                @SuppressLint("Range") Float flag5 = cursor.getFloat(cursor.getColumnIndex(RouteDB.DELAY));

                ControlData controlData = new ControlData(id);
                controlData.setRoll(flag1);
                controlData.setPitch(flag2);
                controlData.setThrottle(flag3);
                controlData.setYaw(flag4);
                controlData.setDelay(flag5);
                result.add(controlData);
            }
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
        return result;
    }

    private void deleteData(ControlData controlData) {
        if (dbReader == null) {
            return;
        }
        Intent intent = new Intent(EditorActivity.this, ViewActivity.class);
        intent.putExtra("ID", String.valueOf(controlData.id));
        startActivity(intent);
    }


    @Override
    protected void onResume() {
        super.onResume();
        dataAdapter.refresh(loadNotesFromDatabase());
    }

    private boolean isFlightControllerAvailable() {
        return null != aircraft;
    }

}
