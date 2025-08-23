package com.idiot.re_point.auth.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * 프론트가 소셜 로그인 완료 후 서버로 보내는 페이로드
 * - uid는 path로 받고, 나머지 필드는 body에 담아 보냄
 */
@Getter @Setter
public class AuthLoginRequest {
    private String name;
    private String email;
    private String profileUrl;
    private String address;
    private String loginProvider; // "google" | "kakao" 등
}