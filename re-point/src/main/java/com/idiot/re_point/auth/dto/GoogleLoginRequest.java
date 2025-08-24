// com/idiot/re_point/auth/dto/GoogleLoginRequest.java
package com.idiot.re_point.auth.dto;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class GoogleLoginRequest {
    private String idToken;   // 클라이언트가 보내는 Google ID Token
    private String address;   // 선택
}