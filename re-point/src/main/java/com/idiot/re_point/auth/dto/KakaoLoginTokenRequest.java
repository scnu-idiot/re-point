package com.idiot.re_point.auth.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter @NoArgsConstructor
public class KakaoLoginTokenRequest {
    private String accessToken;   // 프론트에서 받은 카카오 액세스 토큰
    private String address;       // 선택: 지역 문자열 (없으면 빈 문자열로)
}