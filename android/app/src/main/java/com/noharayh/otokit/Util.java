package com.noharayh.otokit;

import static androidx.core.content.ContextCompat.getSystemService;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.widget.Toast;

import com.noharayh.otokit.DataContext;

import java.util.HashSet;
import java.util.Objects;
import java.util.Set;

public class Util {
    public static Set<Integer> getDifficulties() {
        return new HashSet<>(DataContext.Difficulties);
    }

    public static void copyText(Context context, String link) {
        ClipboardManager clipboard = Objects.requireNonNull(getSystemService(context, ClipboardManager.class));
        ClipData clip = ClipData.newPlainText("link", link);
        clipboard.setPrimaryClip(clip);
        Toast.makeText(context, "已复制链接，请在微信中粘贴并打开", Toast.LENGTH_SHORT).show();
    }
}
