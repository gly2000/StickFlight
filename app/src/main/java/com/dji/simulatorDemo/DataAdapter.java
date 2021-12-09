package com.dji.simulatorDemo;

import android.annotation.SuppressLint;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.dji.simulatorDemo.beans.ControlData;


import java.util.ArrayList;
import java.util.List;

public class DataAdapter extends RecyclerView.Adapter<DataViewHolder> {

    private final DataOperator operator;
    private final List<ControlData> data = new ArrayList<>();

    public DataAdapter(DataOperator operator) {
        this.operator = operator;
    }

    @SuppressLint("NotifyDataSetChanged")
    public void refresh(List<ControlData> newNotes) {
        data.clear();
        if (newNotes != null) {
            data.addAll(newNotes);
        }
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public DataViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View itemView = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.point, parent, false);
        return new DataViewHolder(itemView, operator);
    }

    @Override
    public void onBindViewHolder(@NonNull DataViewHolder holder, int position) {
        holder.bind(data.get(position));
    }

    @Override
    public int getItemCount() {
        return data.size();
    }
}
