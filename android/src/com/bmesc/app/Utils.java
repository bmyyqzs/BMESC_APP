package com.bmesc.app;

import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.graphics.Rect;
import android.location.LocationManager;
import android.os.Build;
import android.provider.Settings;
import android.provider.Settings.SettingNotFoundException;
import android.text.TextUtils;
import android.view.Window;
import android.view.WindowInsets;

public class Utils
{
    public static void startVForegroundService(Context ctx) {
        Intent intent = new Intent(ctx, VForegroundService.class);
        intent.setAction(VForegroundService.ACTION_START_FOREGROUND_SERVICE);
        ctx.startService(intent);
    }

    public static void stopVForegroundService(Context ctx) {
        Intent intent = new Intent(ctx, VForegroundService.class);
        intent.setAction(VForegroundService.ACTION_STOP_FOREGROUND_SERVICE);
        ctx.startService(intent);
    }

    public static boolean checkLocationEnabled(Context ctx) {
        int locationMode = 0;
        String locationProviders;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            LocationManager lm = (LocationManager) ctx.getSystemService(Context.LOCATION_SERVICE);
            return lm.isLocationEnabled();
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT){
            try {
                locationMode = Settings.Secure.getInt(ctx.getContentResolver(), Settings.Secure.LOCATION_MODE);
            } catch (SettingNotFoundException e) {
                e.printStackTrace();
                return false;
            }

            return locationMode != Settings.Secure.LOCATION_MODE_OFF;
        } else {
            locationProviders = Settings.Secure.getString(ctx.getContentResolver(), Settings.Secure.LOCATION_PROVIDERS_ALLOWED);
            return !TextUtils.isEmpty(locationProviders);
        }
    }

    public static Activity getActivity(Context context) {
        if (context == null) return null;
        if (context instanceof Activity) return (Activity) context;
        if (context instanceof ContextWrapper) return getActivity(((ContextWrapper)context).getBaseContext());
        return null;
    }

    public static int topBarHeight(Context ctx) {
        if (Build.VERSION.SDK_INT >= 35) {
            WindowInsets windowInsets = getActivity(ctx).getWindow().getDecorView().getRootWindowInsets();
            return windowInsets.getInsets(WindowInsets.Type.systemBars()).top;
        } else {
            return 0;
        }
    }

    public static int bottomBarHeight(Context ctx) {
        if (Build.VERSION.SDK_INT >= 35) {
            WindowInsets windowInsets = getActivity(ctx).getWindow().getDecorView().getRootWindowInsets();
            return windowInsets.getInsets(WindowInsets.Type.systemBars()).bottom;
        } else {
            return 0;
        }
    }

    public static int rightBarHeight(Context ctx) {
        if (Build.VERSION.SDK_INT >= 35) {
            WindowInsets windowInsets = getActivity(ctx).getWindow().getDecorView().getRootWindowInsets();
            return windowInsets.getInsets(WindowInsets.Type.systemBars()).right;
        } else {
            return 0;
        }
    }

    public static int leftBarHeight(Context ctx) {
        if (Build.VERSION.SDK_INT >= 35) {
            WindowInsets windowInsets = getActivity(ctx).getWindow().getDecorView().getRootWindowInsets();
            return windowInsets.getInsets(WindowInsets.Type.systemBars()).left;
        } else {
            return 0;
        }
    }
}
