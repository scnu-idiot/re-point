package com.idiot.re_point.auth.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.idiot.re_point.auth.dto.KakaoMeResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;

@Service
@RequiredArgsConstructor
public class KakaoAuthService {

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * 카카오 액세스 토큰을 검증하고 사용자 프로필(me) 응답을 반환
     */
    public KakaoMeResponse getUserMe(String accessToken) throws IOException {
        URL url = new URL("https://kapi.kakao.com/v2/user/me");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setRequestProperty(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken);
        conn.setRequestProperty(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE);

        int code = conn.getResponseCode();
        if (code != 200) {
            throw new IOException("Kakao /v2/user/me failed. HTTP " + code);
        }
        return objectMapper.readValue(conn.getInputStream(), KakaoMeResponse.class);
    }
}