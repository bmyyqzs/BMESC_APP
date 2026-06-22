package com.bmesc.app;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.os.Build;
import android.os.IBinder;

import com.bmesc.app.R;

public class VForegroundService extends Service {
    public static final String ACTION_START_FOREGROUND_SERVICE = "ACTION_START_FOREGROUND_SERVICE";
    public static final String ACTION_STOP_FOREGROUND_SERVICE = "ACTION_STOP_FOREGROUND_SERVICE";
    public static final String ACTION_STOP = "ACTION_STOP";

    public VForegroundService() {
    }

    @Override
    public IBinder onBind(Intent intent) {
        throw new UnsupportedOperationException("Not implemented");
    }

    @Override
    public void onCreate() {
        super.onCreate();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if(intent != null)
        {
            String action = intent.getAction();

            switch (action)
            {
                case ACTION_START_FOREGROUND_SERVICE:
                    startForegroundService();
                    break;
                case ACTION_STOP_FOREGROUND_SERVICE:
                    stopForegroundService();
                    break;
                case ACTION_STOP:
                    stopForegroundService();
                    break;
            }
        }
        return super.onStartCommand(intent, flags, startId);
    }

    private void startForegroundService()
    {
        Intent intent = new Intent();
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE);

        Notification.Builder builder;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            String channelId = "BMESC_CHANNEL";
            NotificationChannel channel = new NotificationChannel(channelId, "BMESC", NotificationManager.IMPORTANCE_DEFAULT);
            channel.setDescription("BMESC Background Service");
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
            builder = new Notification.Builder(this, channelId);
        } else {
            builder = new Notification.Builder(this);
        }

        builder.setContentTitle("BMESC");
        builder.setContentText("BMESC is running in the background.");

        builder.setWhen(System.currentTimeMillis());
        builder.setSmallIcon(R.drawable.icon);

        Intent stopIntent = new Intent(this, VForegroundService.class);
        stopIntent.setAction(ACTION_STOP);
        PendingIntent pendingPrevIntent = PendingIntent.getService(this, 0, stopIntent, PendingIntent.FLAG_IMMUTABLE);
        Notification.Action prevAction = new Notification.Action(android.R.drawable.ic_media_pause, "Stop", pendingPrevIntent);
        builder.addAction(prevAction);

        startForeground(1, builder.build(), ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION);
    }

    private void stopForegroundService()
    {
        stopForeground(true);
        stopSelf();
    }
}
