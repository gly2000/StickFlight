package com.dji.simulatorDemo.beans;

import java.util.Date;

public class ControlData {
    public long id;
    private Float roll;
    private Float pitch;
    private Float throttle;
    private Float yaw;
    private Float delay;

    public ControlData(long id) {
        this.id = id;
    }

    public Float getRoll() {
        return roll;
    }

    public void setRoll(Float roll) {
        this.roll = roll;
    }

    public Float getPitch() {
        return pitch;
    }

    public void setPitch(Float pitch) {
        this.pitch = pitch;
    }

    public Float getThrottle() {
        return throttle;
    }

    public void setThrottle(Float throttle) {
        this.throttle = throttle;
    }

    public Float getYaw() {
        return yaw;
    }

    public void setYaw(Float yaw) {
        this.yaw = yaw;
    }

    public Float getDelay() {
        return delay;
    }

    public void setDelay(Float delay) {
        this.delay = delay;
    }

}
