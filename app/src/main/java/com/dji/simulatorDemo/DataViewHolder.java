package com.dji.simulatorDemo;

import android.content.Intent;
import android.view.View;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.dji.simulatorDemo.beans.ControlData;

public class DataViewHolder extends RecyclerView.ViewHolder{

    private TextView rollText;
    private TextView pitchText;
    private TextView throttleText;
    private TextView yawText;
    private TextView delayText;
    private ImageButton deleteBtn;

    private final DataOperator operator;

    public DataViewHolder(@NonNull View itemView, DataOperator operator) {
        super(itemView);

        rollText = (TextView) itemView.findViewById(R.id.roll);
        pitchText = (TextView) itemView.findViewById(R.id.pitch);
        throttleText = (TextView) itemView.findViewById(R.id.throttle);
        yawText = (TextView) itemView.findViewById(R.id.yaw);
        delayText = (TextView) itemView.findViewById(R.id.delay);
        deleteBtn = (ImageButton) itemView.findViewById(R.id.btn_delete);
        this.operator = operator;
    }

    public void bind(ControlData controlData) {
        rollText.setText(controlData.getRoll().toString());
        pitchText.setText(controlData.getPitch().toString());
        throttleText.setText(controlData.getThrottle().toString());
        yawText.setText(controlData.getYaw().toString());
        delayText.setText(controlData.getDelay().toString());

        deleteBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                operator.deleteData(controlData);
            }
        });
    }
}
