package com.idiot.re_point.user.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * 프로필 부분 수정용 DTO (null인 필드는 건드리지 않음)
 */
@Getter
@Setter
public class UpdateUserRequest {
    private String name;
    private String email;        // 필요 없다면 제거 가능
    private String profileUrl;
    private String address;
    private String loginProvider; // "google" | "kakao" 등
    private Long point;          // 포인트 수정이 필요 없다면 null로 둠
}