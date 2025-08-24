package com.idiot.re_point.auth.dto;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class KakaoLoginRequest {
    // 프론트에서 받은 카카오 access_token
    private String accessToken;
}