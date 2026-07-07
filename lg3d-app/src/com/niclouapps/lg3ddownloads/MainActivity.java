package com.niclouapps.lg3ddownloads;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.KeyEvent;
import android.webkit.DownloadListener;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private WebView myWebView;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        myWebView = (WebView) findViewById(R.id.webview);
        
        // Configurações da WebView
        WebSettings webSettings = myWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        
        // Evita que links abram fora do aplicativo usando classes nomeadas para evitar bugs do compilador d8
        myWebView.setWebViewClient(new MyWebViewClient(this));

        // Ouvinte de downloads para links do site usando classes nomeadas
        myWebView.setDownloadListener(new MyDownloadListener(this));

        // Carrega o site de downloads
        myWebView.loadUrl("http://lg3d-downloads.surge.sh");
    }

    // Classe nomeada interna estática para o WebViewClient
    private static class MyWebViewClient extends WebViewClient {
        private final Activity activity;

        public MyWebViewClient(Activity activity) {
            this.activity = activity;
        }

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            if (url.endsWith(".apk")) {
                Intent intent = new Intent(Intent.ACTION_VIEW);
                intent.setData(Uri.parse(url));
                activity.startActivity(intent);
                return true;
            }
            view.loadUrl(url);
            return true;
        }
    }

    // Classe nomeada interna estática para o DownloadListener
    private static class MyDownloadListener implements DownloadListener {
        private final Activity activity;

        public MyDownloadListener(Activity activity) {
            this.activity = activity;
        }

        public void onDownloadStart(String url, String userAgent,
                String contentDisposition, String mimetype,
                long contentLength) {
            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setData(Uri.parse(url));
            activity.startActivity(intent);
        }
    }

    // Voltar no histórico da WebView com o botão físico Voltar do celular
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if ((keyCode == KeyEvent.KEYCODE_BACK) && myWebView.canGoBack()) {
            myWebView.goBack();
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }
}
