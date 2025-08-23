package com.idiot.re_point.user.dto;

import com.idiot.re_point.user.model.User;
import lombok.*;

@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDto {
    private String uid;
    private String name;
    private String email;
    private String profileUrl;
    private String address;
    private String loginProvider;
    private Long point;

    // 지역 정보
    private String regionProvince;
    private String regionCity;
    private String regionDistrict;

    private String createdAt;
    private String updatedAt;

    public static UserDto from(User u) {
        if (u == null) return null;
        return UserDto.builder()
                .uid(u.getUid())
                .name(u.getName())
                .email(u.getEmail())
                .profileUrl(u.getProfileUrl())
                .address(u.getAddress())
                .loginProvider(u.getLoginProvider())
                .point(u.getPoint())
                .regionProvince(u.getRegionProvince())
                .regionCity(u.getRegionCity())
                .regionDistrict(u.getRegionDistrict())
                .createdAt(u.getCreatedAt() == null ? null : u.getCreatedAt().toString())
                .updatedAt(u.getUpdatedAt() == null ? null : u.getUpdatedAt().toString())
                .build();
    }
}