// com/idiot/re_point/auth/service/GoogleAuthService.java
package com.idiot.re_point.auth.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Collections;

@Service
@RequiredArgsConstructor
public class GoogleAuthService {

    @Value("${google.oauth.client-id}")
    private String clientId;

    private final NetHttpTransport transport = new NetHttpTransport();
    private final GsonFactory jsonFactory = GsonFactory.getDefaultInstance();

    public GoogleIdToken verify(String idTokenStr) throws Exception {
        GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(transport, jsonFactory)
                .setAudience(Collections.singletonList(clientId)) // aud 일치 검증
                .build();

        return verifier.verify(idTokenStr); // 유효하면 GoogleIdToken, 아니면 null
    }
}