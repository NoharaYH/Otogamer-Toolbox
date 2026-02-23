package com.noharayh.toolbox.crawler;

public interface Callback {
    void onResponse(Object result);

    default void onError(Exception error) {
    }

}
