package com.idiot.re_point.auth.controller;

import com.idiot.re_point.auth.dto.AuthLoginRequest;
import com.idiot.re_point.auth.dto.KakaoLoginTokenRequest;
import com.idiot.re_point.auth.dto.KakaoMeResponse;
import com.idiot.re_point.auth.service.KakaoAuthService;
import com.idiot.re_point.user.dto.UserDto;
import com.idiot.re_point.user.model.User;
import com.idiot.re_point.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.ExecutionException;

/**
 * 소셜 로그인 완료 후 서버 동기화
 * - /api/auth/login/{uid} : 프론트가 이미 검증해서 uid/프로필을 넘겨주는 간단 버전(신뢰 기반)
 * - /api/auth/kakao/login : 카카오 access_token을 받아 백엔드가 직접 검증 후 Firestore upsert
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;
    private final KakaoAuthService kakaoAuthService;

    /**
     * (기존) 프론트가 검증을 마친 사용자 정보를 받아 upsert
     */
    @PostMapping("/login/{uid}")
    public ResponseEntity<?> login(@PathVariable String uid,
                                   @RequestBody AuthLoginRequest req)
            throws ExecutionException, InterruptedException {

        User u = User.builder()
                .uid(uid)
                .name(req.getName())
                .email(req.getEmail())
                .profileUrl(req.getProfileUrl())
                .address(req.getAddress())
                .loginProvider(req.getLoginProvider()) // "google" | "kakao"
                .point(0L) // 최초 0 (기존 문서가 있으면 UserService에서 createdAt 유지)
                .build();

        userService.upsert(uid, u);

        User saved = userService.getByUid(uid);
        return ResponseEntity.ok(UserDto.from(saved));
    }

    /**
     * (추가) 카카오 access_token 검증 → 카카오 프로필 조회 → Firestore upsert
     * 요청 바디: {"accessToken":"카카오액세스토큰", "address":""}
     * 저장 uid 규칙: 카카오 사용자 id 그대로 사용(예: "3712345678")
     */
    @PostMapping("/kakao/login")
    public ResponseEntity<?> kakaoLogin(@RequestBody KakaoLoginTokenRequest body) throws Exception {
        if (body == null || body.getAccessToken() == null || body.getAccessToken().isBlank()) {
            return ResponseEntity.badRequest().body("{\"error\":\"accessToken_required\"}");
        }

        // 1) 카카오에 토큰 검증 & 프로필 요청
        KakaoMeResponse me = kakaoAuthService.getUserMe(body.getAccessToken());
        if (me == null || me.getId() == null) {
            return ResponseEntity.status(401).body("{\"error\":\"invalid_kakao_token\"}");
        }

        // 2) uid = 카카오 id (접두사 없이)
        String uid = String.valueOf(me.getId());

        // 3) Firestore upsert용 사용자 스냅샷 구성
        String name  = (me.getKakaoAccount() != null && me.getKakaoAccount().getProfile() != null)
                ? me.getKakaoAccount().getProfile().getNickname() : "";
        String email = (me.getKakaoAccount() != null) ? me.getKakaoAccount().getEmail() : "";
        String photo = (me.getKakaoAccount() != null && me.getKakaoAccount().getProfile() != null)
                ? me.getKakaoAccount().getProfile().getProfileImageUrl() : "";

        User u = User.builder()
                .uid(uid)
                .name(name == null ? "" : name)
                .email(email == null ? "" : email)
                .profileUrl(photo == null ? "" : photo)
                .address(body.getAddress() == null ? "" : body.getAddress())
                .loginProvider("kakao")
                .point(0L)
                .build();

        // 4) 저장 & 반환 (createdAt/updatedAt은 서비스에서 처리)
        userService.upsert(uid, u);
        User saved = userService.getByUid(uid);
        return ResponseEntity.ok(UserDto.from(saved));
    }
}