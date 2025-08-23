package com.idiot.re_point.user.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * 전체 사용자 정보를 생성/수정(upsert)할 때 받는 요청 바디
 * - 모든 필드는 선택(optional)로 두고, 들어온 값만 업데이트
 * - null 이면 기존 값 유지(서비스 레벨에서 merge 처리)
 */
@Getter
@Setter
@NoArgsConstructor
public class UpsertUserRequest {

    @Schema(description = "표시 이름(닉네임)", example = "홍길동")
    private String name;

    @Schema(description = "이메일", example = "gildong@example.com")
    private String email;

    @Schema(description = "프로필 이미지 URL", example = "https://example.com/profile.png")
    private String profileUrl;

    @Schema(description = "사용자 주소(또는 지역표시 문자열)", example = "서울특별시 강남구")
    private String address;

    @Schema(description = "로그인 제공자", example = "google", allowableValues = {"google", "kakao"})
    private String loginProvider;
}