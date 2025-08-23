package com.idiot.re_point.user.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter
@NoArgsConstructor
public class RegionUpdateRequest {
    private String province; // 시/도
    private String city;     // 시/군/구
    private String district; // 읍/면/동
}